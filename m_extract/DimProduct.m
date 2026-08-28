let
    Source = Stg_Product,

    MergedModel = Table.NestedJoin(Source, {"ProductModelID"}, Stg_ProductModel, {"ProductModelID"}, "ModelData", JoinKind.LeftOuter),
    ExpandedModel = Table.ExpandTableColumn(MergedModel, "ModelData", {"ModelName"}, {"ModelName"}),

    MergedCategory = Table.NestedJoin(ExpandedModel, {"ProductCategoryID"}, Stg_ProductCategory, {"ProductCategoryID"}, "CategoryData", JoinKind.LeftOuter),
    ExpandedCategory = Table.ExpandTableColumn(MergedCategory, "CategoryData",
        {"SubcategoryName", "CategoryName", "CategoryLevel"},
        {"SubcategoryName", "CategoryName", "CategoryLevel"}),

    ReorderedColumns = Table.ReorderColumns(ExpandedCategory, {
        "ProductID", "ProductName", "ProductNumber", "ModelName", "CategoryName", "SubcategoryName",
        "Color", "Size", "Weight", "StandardCost", "ListPrice", "Margin", "MarginPercent",
        "ProductStatus", "SellStartDate", "SellEndDate", "DiscontinuedDate", "ProductCategoryID"
    })
in
    ReorderedColumns
