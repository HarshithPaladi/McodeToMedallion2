let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_ProductModel = Source{[Schema="SalesLT",Item="ProductModel"]}[Data]
in
    SalesLT_ProductModel
