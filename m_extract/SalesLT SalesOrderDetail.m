let
    Source = Sql.Database("hydraaserver.database.windows.net", "hydradatabase"),
    SalesLT_SalesOrderDetail = Source{[Schema="SalesLT",Item="SalesOrderDetail"]}[Data]
in
    SalesLT_SalesOrderDetail
