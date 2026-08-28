let
    Source = fnGetSalesLTTable("SalesOrderHeader"),
    OrderDates = Table.SelectColumns(Source, {"OrderDate"}),
    ChangedOrderDateType = Table.TransformColumnTypes(OrderDates, {{"OrderDate", type datetime}}),

    MinDate = Date.From(List.Min(ChangedOrderDateType[OrderDate])),
    MaxDate = Date.From(List.Max(ChangedOrderDateType[OrderDate])),

    StartDate = #date(Date.Year(MinDate), 1, 1),
    EndDate = #date(Date.Year(MaxDate), 12, 31),

    NumberOfDays = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, NumberOfDays, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),

    AddedYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
    AddedMonthNumber = Table.AddColumn(AddedYear, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddedMonthName = Table.AddColumn(AddedMonthNumber, "MonthName", each Date.ToText([Date], "MMMM"), type text),
    AddedQuarter = Table.AddColumn(AddedMonthName, "Quarter", each "Q" & Number.ToText(Date.QuarterOfYear([Date])), type text),
    AddedYearMonth = Table.AddColumn(AddedQuarter, "YearMonth", each Date.ToText([Date], "yyyy-MM"), type text),
    AddedDayOfWeek = Table.AddColumn(AddedYearMonth, "DayOfWeekName", each Date.ToText([Date], "dddd"), type text),
    AddedIsWeekend = Table.AddColumn(AddedDayOfWeek, "IsWeekend", each Date.DayOfWeek([Date], Day.Monday) >= 5, type logical)
in
    AddedIsWeekend
