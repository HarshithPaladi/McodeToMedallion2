let
    Source = Stg_ProductCategory,
    ReorderedColumns = Table.ReorderColumns(Source,
        {"ProductCategoryID", "CategoryName", "SubcategoryName", "CategoryLevel", "ParentProductCategoryID"})
in
    ReorderedColumns
