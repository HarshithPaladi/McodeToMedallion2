let
    Source = fnGetSalesLTTable("Address"),

    SelectedColumns = Table.SelectColumns(Source,
        {"AddressID", "AddressLine1", "AddressLine2", "City", "StateProvince", "CountryRegion", "PostalCode", "ModifiedDate"}),

    RenamedColumns = Table.RenameColumns(SelectedColumns, {
        {"StateProvince", "State"}, {"CountryRegion", "Country"}, {"ModifiedDate", "LastModifiedDate"}
    }),

    ChangedType = Table.TransformColumnTypes(RenamedColumns, {
        {"AddressID", Int64.Type}, {"AddressLine1", type text}, {"AddressLine2", type text},
        {"City", type text}, {"State", type text}, {"Country", type text},
        {"PostalCode", type text}, {"LastModifiedDate", type datetime}
    }),

    TrimmedText = Table.TransformColumns(ChangedType, {
        {"City", Text.Trim, type text}, {"State", Text.Trim, type text}, {"Country", Text.Trim, type text}
    }),

    AddedFullAddress = Table.AddColumn(TrimmedText, "FullAddress", each
        Text.Combine(List.RemoveNulls({[AddressLine1], [AddressLine2], [City], [State], [PostalCode], [Country]}), ", "),
        type text),

    RemovedDuplicates = Table.Distinct(AddedFullAddress, {"AddressID"})
in
    RemovedDuplicates
