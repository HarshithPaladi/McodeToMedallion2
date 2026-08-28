let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_Address = Source{[Schema="SalesLT",Item="Address"]}[Data]
in
    SalesLT_Address
