let
    SourceDetail = fnGetSalesLTTable("SalesOrderDetail"),

    SelectedDetailColumns = Table.SelectColumns(SourceDetail,
        {"SalesOrderID", "SalesOrderDetailID", "OrderQty", "ProductID", "UnitPrice", "UnitPriceDiscount", "LineTotal"}),

    ChangedDetailTypes = Table.TransformColumnTypes(SelectedDetailColumns, {
        {"SalesOrderID", Int64.Type}, {"SalesOrderDetailID", Int64.Type}, {"OrderQty", Int64.Type},
        {"ProductID", Int64.Type}, {"UnitPrice", type number}, {"UnitPriceDiscount", type number}, {"LineTotal", type number}
    }),

    // Null handling: enforce 0 for no-discount lines
    ReplacedDiscountNulls = Table.ReplaceValue(ChangedDetailTypes, null, 0, Replacer.ReplaceValue, {"UnitPriceDiscount"}),

    // Remove unnecessary records: zero-quantity lines carry no sales value
    FilteredZeroQty = Table.SelectRows(ReplacedDiscountNulls, each [OrderQty] > 0),

    RemovedDuplicateLines = Table.Distinct(FilteredZeroQty, {"SalesOrderDetailID"}),

    // Merge SalesOrderHeader: bring header ATTRIBUTES only (not $ totals) onto each line
    SourceHeader = fnGetSalesLTTable("SalesOrderHeader"),
    SelectedHeaderColumns = Table.SelectColumns(SourceHeader, {
        "SalesOrderID", "OrderDate", "DueDate", "ShipDate", "Status", "OnlineOrderFlag",
        "SalesOrderNumber", "CustomerID", "ShipToAddressID", "BillToAddressID", "ShipMethod"
    }),
    ChangedHeaderTypesMain = Table.TransformColumnTypes(SelectedHeaderColumns, {
        {"SalesOrderID", Int64.Type},
        {"Status", Int64.Type}, {"OnlineOrderFlag", type logical}, {"SalesOrderNumber", type text},
        {"CustomerID", Int64.Type}, {"ShipToAddressID", Int64.Type}, {"BillToAddressID", Int64.Type}, {"ShipMethod", type text}
    }),

    // Date fix: same ISO-text issue as Stg_Product - go through datetime first, then take the date
    ChangedHeaderDatesToDateTime = Table.TransformColumnTypes(ChangedHeaderTypesMain, {
        {"OrderDate", type datetime}, {"DueDate", type datetime}, {"ShipDate", type datetime}
    }),
    ChangedHeaderTypes = Table.TransformColumns(ChangedHeaderDatesToDateTime, {
        {"OrderDate", Date.From, type date},
        {"DueDate", Date.From, type date},
        {"ShipDate", Date.From, type date}
    }),

    MergedHeader = Table.NestedJoin(RemovedDuplicateLines, {"SalesOrderID"}, ChangedHeaderTypes, {"SalesOrderID"}, "HeaderData", JoinKind.Inner),
    ExpandedHeader = Table.ExpandTableColumn(MergedHeader, "HeaderData", {
        "OrderDate", "DueDate", "ShipDate", "Status", "OnlineOrderFlag", "SalesOrderNumber",
        "CustomerID", "ShipToAddressID", "BillToAddressID", "ShipMethod"
    }),

    // Join Product: pull current ListPrice to compare against price actually sold at
    MergedProduct = Table.NestedJoin(ExpandedHeader, {"ProductID"}, Stg_Product, {"ProductID"}, "ProductData", JoinKind.LeftOuter),
    ExpandedProduct = Table.ExpandTableColumn(MergedProduct, "ProductData", {"ListPrice", "ProductCategoryID"}, {"CurrentListPrice", "ProductCategoryID"}),

    // Join Customer: denormalize name/segment directly onto the fact for quick-build visuals
    MergedCustomer = Table.NestedJoin(ExpandedProduct, {"CustomerID"}, Stg_Customer, {"CustomerID"}, "CustomerData", JoinKind.LeftOuter),
    ExpandedCustomer = Table.ExpandTableColumn(MergedCustomer, "CustomerData", {"FullName", "CustomerType"}, {"CustomerName", "CustomerType"}),

    // Derived column: net revenue after discount, computed independently for reconciliation against LineTotal
    AddedNetAmount = Table.AddColumn(ExpandedCustomer, "NetAmount", each
        Number.Round([OrderQty] * [UnitPrice] * (1 - [UnitPriceDiscount]), 2), type number),

    // Derived column: discount amount in currency
    AddedDiscountAmount = Table.AddColumn(AddedNetAmount, "DiscountAmount", each
        Number.Round([OrderQty] * [UnitPrice] * [UnitPriceDiscount], 2), type number),

    // Derived column: variance between price sold at and current catalog price
    AddedPriceVariance = Table.AddColumn(AddedDiscountAmount, "PriceVarianceVsListPrice", each
        [UnitPrice] - [CurrentListPrice], type number),

    // Conditional column: order channel
    AddedOrderChannel = Table.AddColumn(AddedPriceVariance, "OrderChannel", each
        if [OnlineOrderFlag] = true then "Online" else "Sales Rep", type text),

    // Conditional column: ship-to vs bill-to comparison flag
    AddedIsShipBillSame = Table.AddColumn(AddedOrderChannel, "IsShipBillSame", each
        [ShipToAddressID] = [BillToAddressID], type logical),

    // Conditional column: decode numeric SalesLT status code to business text
    AddedOrderStatus = Table.AddColumn(AddedIsShipBillSame, "OrderStatusDescription", each
        if [Status] = 1 then "In Process"
        else if [Status] = 2 then "Approved"
        else if [Status] = 3 then "Backordered"
        else if [Status] = 4 then "Rejected"
        else if [Status] = 5 then "Shipped"
        else if [Status] = 6 then "Cancelled"
        else "Unknown", type text),

    RemovedHelperColumns = Table.RemoveColumns(AddedOrderStatus, {"Status"})
in
    RemovedHelperColumns
