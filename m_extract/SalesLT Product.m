let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_Product = Source{[Schema="SalesLT",Item="Product"]}[Data]
in
    SalesLT_Product
