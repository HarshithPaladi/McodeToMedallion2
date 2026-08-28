let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_ProductCategory = Source{[Schema="SalesLT",Item="ProductCategory"]}[Data]
in
    SalesLT_ProductCategory
