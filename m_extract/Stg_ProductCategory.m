let
    Source = fnGetSalesLTTable("ProductCategory"),

    SelectedColumns = Table.SelectColumns(Source, {"ProductCategoryID", "ParentProductCategoryID", "Name"}),

    ChangedType = Table.TransformColumnTypes(SelectedColumns, {
        {"ProductCategoryID", Int64.Type}, {"ParentProductCategoryID", Int64.Type}, {"Name", type text}
    }),

    RenamedColumns = Table.RenameColumns(ChangedType, {{"Name", "SubcategoryName"}}),

    MergedWithParent = Table.NestedJoin(RenamedColumns, {"ParentProductCategoryID"},
        RenamedColumns, {"ProductCategoryID"}, "ParentLookup", JoinKind.LeftOuter),

    ExpandedParent = Table.ExpandTableColumn(MergedWithParent, "ParentLookup", {"SubcategoryName"}, {"CategoryName"}),

    AddedFinalCategoryName = Table.AddColumn(ExpandedParent, "FinalCategoryName", each
        if [CategoryName] = null then [SubcategoryName] else [CategoryName], type text),

    AddedCategoryLevel = Table.AddColumn(AddedFinalCategoryName, "CategoryLevel", each
        if [ParentProductCategoryID] = null then "Category" else "Subcategory", type text),

    RemovedHelperColumn = Table.RemoveColumns(AddedCategoryLevel, {"CategoryName"}),
    FinalColumns = Table.RenameColumns(RemovedHelperColumn, {{"FinalCategoryName", "CategoryName"}})
in
    FinalColumns
