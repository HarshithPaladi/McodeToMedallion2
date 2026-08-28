let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_ProductDescription = Source{[Schema="SalesLT",Item="ProductDescription"]}[Data]
in
    SalesLT_ProductDescription
