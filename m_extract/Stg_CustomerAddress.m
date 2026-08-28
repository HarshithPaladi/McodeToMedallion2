let
    Source = fnGetSalesLTTable("CustomerAddress"),

    SelectedColumns = Table.SelectColumns(Source, {"CustomerID", "AddressID", "AddressType", "ModifiedDate"}),

    ChangedType = Table.TransformColumnTypes(SelectedColumns, {
        {"CustomerID", Int64.Type}, {"AddressID", Int64.Type}, {"AddressType", type text}, {"ModifiedDate", type datetime}
    }),

    FilteredMainOffice = Table.SelectRows(ChangedType, each [AddressType] = "Main Office"),

    RemovedDuplicates = Table.Distinct(FilteredMainOffice, {"CustomerID"}),

    RenamedColumns = Table.RenameColumns(RemovedDuplicates, {{"ModifiedDate", "LinkModifiedDate"}})
in
    RenamedColumns
