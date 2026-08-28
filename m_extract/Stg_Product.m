let
    Source = fnGetSalesLTTable("Product"),

    SelectedColumns = Table.SelectColumns(Source, {
        "ProductID", "Name", "ProductNumber", "Color", "StandardCost", "ListPrice",
        "Size", "Weight", "ProductCategoryID", "ProductModelID",
        "SellStartDate", "SellEndDate", "DiscontinuedDate", "ModifiedDate"
    }),

    RenamedColumns = Table.RenameColumns(SelectedColumns, {
        {"Name", "ProductName"}, {"ModifiedDate", "LastModifiedDate"}
    }),

    ChangedType = Table.TransformColumnTypes(RenamedColumns, {
        {"ProductID", Int64.Type}, {"ProductName", type text}, {"ProductNumber", type text},
        {"Color", type text}, {"StandardCost", type number}, {"ListPrice", type number},
        {"Size", type text}, {"Weight", type number}, {"ProductCategoryID", Int64.Type},
        {"ProductModelID", Int64.Type}, {"LastModifiedDate", type datetime}
    }),

    // Date fix: the source stores dates as ISO text with a "T...0000000" time part, which
    // "type date" can't parse directly. Go through "type datetime" first, then take the date.
    ChangedDatesToDateTime = Table.TransformColumnTypes(ChangedType, {
        {"SellStartDate", type datetime}, {"SellEndDate", type datetime}, {"DiscontinuedDate", type datetime}
    }),
    ChangedDatesToDate = Table.TransformColumns(ChangedDatesToDateTime, {
        {"SellStartDate", Date.From, type date},
        {"SellEndDate", Date.From, type date},
        {"DiscontinuedDate", Date.From, type date}
    }),

    // Null handling: make "unspecified" explicit rather than blank
    ReplacedColorNulls = Table.ReplaceValue(ChangedDatesToDate, null, "N/A", Replacer.ReplaceValue, {"Color"}),

    // Conditional column: product lifecycle status
    AddedProductStatus = Table.AddColumn(ReplacedColorNulls, "ProductStatus", each
        if [DiscontinuedDate] <> null then "Discontinued"
        else if [SellEndDate] <> null and [SellEndDate] < DateTime.Date(DateTime.LocalNow()) then "Inactive"
        else "Active", type text),

    // Derived columns: margin metrics at the product-master level
    AddedMargin = Table.AddColumn(AddedProductStatus, "Margin", each [ListPrice] - [StandardCost], type number),
    AddedMarginPct = Table.AddColumn(AddedMargin, "MarginPercent", each
        if [ListPrice] = 0 then 0 else ([ListPrice] - [StandardCost]) / [ListPrice], type number),

    RemovedDuplicates = Table.Distinct(AddedMarginPct, {"ProductID"})
in
    RemovedDuplicates
