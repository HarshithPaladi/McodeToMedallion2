let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_ProductModelProductDescription = Source{[Schema="SalesLT",Item="ProductModelProductDescription"]}[Data]
in
    SalesLT_ProductModelProductDescription
