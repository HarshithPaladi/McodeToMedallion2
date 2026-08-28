let
    Source = fnGetSalesLTTable("Customer"),

    SelectedColumns = Table.SelectColumns(Source,
        {"CustomerID", "NameStyle", "Title", "FirstName", "MiddleName", "LastName",
         "Suffix", "CompanyName", "SalesPerson", "EmailAddress", "Phone", "ModifiedDate"}),

    RenamedColumns = Table.RenameColumns(SelectedColumns, {
        {"CompanyName", "Company"},
        {"SalesPerson", "SalesPersonName"},
        {"EmailAddress", "Email"},
        {"ModifiedDate", "LastModifiedDate"}
    }),

    ChangedType = Table.TransformColumnTypes(RenamedColumns, {
        {"CustomerID", Int64.Type}, {"NameStyle", type logical}, {"Title", type text},
        {"FirstName", type text}, {"MiddleName", type text}, {"LastName", type text},
        {"Suffix", type text}, {"Company", type text}, {"SalesPersonName", type text},
        {"Email", type text}, {"Phone", type text}, {"LastModifiedDate", type datetime}
    }),

    ReplacedNulls = Table.ReplaceValue(ChangedType, null, "", Replacer.ReplaceValue,
        {"Title", "MiddleName", "Suffix"}),

    AddedFullName = Table.AddColumn(ReplacedNulls, "FullName", each
        Text.Trim(Text.Combine({[FirstName], [MiddleName], [LastName]}, " ")), type text),

    AddedCustomerType = Table.AddColumn(AddedFullName, "CustomerType", each
        if [Company] <> null and Text.Trim([Company]) <> "" then "Business" else "Individual", type text),

    RemovedDuplicates = Table.Distinct(AddedCustomerType, {"CustomerID"})
in
    RemovedDuplicates
