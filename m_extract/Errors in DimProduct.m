let
Source = DimProduct,
  #"Detected Type Mismatches" = let
    tableWithOnlyPrimitiveTypes = Table.SelectColumns(Source, Table.ColumnsOfType(Source, {type nullable number, type nullable text, type nullable logical, type nullable date, type nullable datetime, type nullable datetimezone, type nullable time, type nullable duration})),
    recordTypeFields = Type.RecordFields(Type.TableRow(Value.Type(tableWithOnlyPrimitiveTypes))),
    fieldNames = Record.FieldNames(recordTypeFields),
    fieldTypes = List.Transform(Record.ToList(recordTypeFields), each [Type]),
    pairs = List.Transform(List.Positions(fieldNames), (i) => {fieldNames{i}, (v) => if v = null or Value.Is(v, fieldTypes{i}) then v else error [Message = "The type of the value does not match the type of the column.", Detail = v], fieldTypes{i}})
in
    Table.TransformColumns(Source, pairs),
  #"Added Index" = Table.AddIndexColumn(#"Detected Type Mismatches", "Row Number" ,1),
  #"Kept Errors" = Table.SelectRowsWithErrors(#"Added Index", {"ProductID", "ProductName", "ProductNumber", "ModelName", "CategoryName", "SubcategoryName", "Color", "Size", "Weight", "ProductModelID", "StandardCost", "ListPrice", "Margin", "LastModifiedDate", "MarginPercent", "ProductStatus", "SellStartDate", "SellEndDate", "DiscontinuedDate", "ProductCategoryID", "CategoryLevel"}),
  #"Reordered Columns" = Table.ReorderColumns(#"Kept Errors", {"Row Number", "ProductID", "ProductName", "ProductNumber", "ModelName", "CategoryName", "SubcategoryName", "Color", "Size", "Weight", "ProductModelID", "StandardCost", "ListPrice", "Margin", "LastModifiedDate", "MarginPercent", "ProductStatus", "SellStartDate", "SellEndDate", "DiscontinuedDate", "ProductCategoryID", "CategoryLevel"}),
    SellStartDate = #"Reordered Columns"{0}[SellStartDate]
in
  SellStartDate
