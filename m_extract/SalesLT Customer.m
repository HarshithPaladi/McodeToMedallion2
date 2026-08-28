let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_Customer = Source{[Schema="SalesLT",Item="Customer"]}[Data]
in
    SalesLT_Customer
