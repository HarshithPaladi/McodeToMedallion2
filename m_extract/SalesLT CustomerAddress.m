let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_CustomerAddress = Source{[Schema="SalesLT",Item="CustomerAddress"]}[Data]
in
    SalesLT_CustomerAddress
