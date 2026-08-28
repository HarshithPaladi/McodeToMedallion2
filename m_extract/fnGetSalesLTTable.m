let
    fnGetSalesLTTable = (TableName as text) as table =>
        let
            Source = Sql.Database(SQLServerName, SQLDatabaseName),
            NavigateToTable = Source{[Schema = "SalesLT", Item = TableName]}[Data]
        in
            NavigateToTable
in
    fnGetSalesLTTable
