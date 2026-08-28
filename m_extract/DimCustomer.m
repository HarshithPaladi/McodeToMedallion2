let
    Source = Stg_Customer,

    MergedAddressLink = Table.NestedJoin(Source, {"CustomerID"}, Stg_CustomerAddress, {"CustomerID"}, "AddressLink", JoinKind.LeftOuter),
    ExpandedAddressLink = Table.ExpandTableColumn(MergedAddressLink, "AddressLink", {"AddressID"}, {"AddressID"}),

    MergedAddress = Table.NestedJoin(ExpandedAddressLink, {"AddressID"}, Stg_Address, {"AddressID"}, "AddressData", JoinKind.LeftOuter),
    ExpandedAddress = Table.ExpandTableColumn(MergedAddress, "AddressData",
        {"City", "State", "Country", "PostalCode", "FullAddress"},
        {"City", "State", "Country", "PostalCode", "FullAddress"}),

    ReorderedColumns = Table.ReorderColumns(ExpandedAddress, {
        "CustomerID", "FullName", "Company", "CustomerType", "SalesPersonName",
        "Email", "Phone", "City", "State", "Country", "PostalCode", "FullAddress"
    })
in
    ReorderedColumns
