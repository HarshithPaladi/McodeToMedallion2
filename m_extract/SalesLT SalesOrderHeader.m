let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_SalesOrderHeader = Source{[Schema="SalesLT",Item="SalesOrderHeader"]}[Data]
in
    SalesLT_SalesOrderHeader
