let
    Source = fnGetSalesLTTable("ProductModel"),

    RemovedColumns = Table.RemoveColumns(Source, {"CatalogDescription", "rowguid"}),

    RenamedColumns = Table.RenameColumns(RemovedColumns, {{"Name", "ModelName"}}),

    ChangedType = Table.TransformColumnTypes(RenamedColumns, {
        {"ProductModelID", Int64.Type}, {"ModelName", type text}, {"ModifiedDate", type datetime}
    }),

    RemovedDuplicates = Table.Distinct(ChangedType, {"ProductModelID"})
in
    RemovedDuplicates
