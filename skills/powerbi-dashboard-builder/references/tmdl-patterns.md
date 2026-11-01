# TMDL Patterns (Power BI semantic model)

TMDL files are indentation-sensitive and use **tabs**. Object names with spaces or special
characters are wrapped in single quotes. Descriptions are written as `///` lines directly
above the object.

## PBIP folder layout

```
<Name>.pbip
<Name>.SemanticModel/
  definition.pbism
  definition/
    database.tmdl
    model.tmdl
    relationships.tmdl
    expressions.tmdl          # shared parameters (server, database)
    tables/
      Date.tmdl
      Customer.tmdl
      'AR Open Items'.tmdl     # file name = table name
      _Measures.tmdl
    roles/
      'BU Managers'.tmdl
<Name>.Report/
  definition.pbir
  definition/ ...              # see report-pbir.md
```

If you are editing an existing project, read `model.tmdl` and one table file first and match
the existing conventions (lineage tags, culture, annotations). Do not invent `lineageTag`
values for new objects; omit them and Power BI Desktop will generate them on save.

## Parameters (expressions.tmdl)

```tmdl
expression ServerName = "myaccount.snowflakecomputing.com" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

expression WarehouseName = "ANALYTICS_WH" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
```

## Fact table

```tmdl
/// One row per open invoice per daily snapshot.
table 'AR Open Items'

	column InvoiceId
		dataType: string
		isHidden
		sourceColumn: INVOICE_ID
		summarizeBy: none

	column CustomerKey
		dataType: int64
		isHidden
		sourceColumn: CUSTOMER_KEY
		summarizeBy: none

	column SnapshotDateKey
		dataType: int64
		isHidden
		sourceColumn: SNAPSHOT_DATE_KEY
		summarizeBy: none

	column OpenAmount
		dataType: decimal
		isHidden
		sourceColumn: OPEN_AMOUNT_USD
		summarizeBy: sum

	column DaysPastDue
		dataType: int64
		sourceColumn: DAYS_PAST_DUE
		summarizeBy: none

	partition 'AR Open Items' = m
		mode: import
		source =
				let
				    Source = Snowflake.Databases(ServerName, WarehouseName),
				    DB = Source{[Name="FINANCE"]}[Data],
				    Schema = DB{[Name="AR"]}[Data],
				    Tbl = Schema{[Name="FCT_AR_OPEN_ITEMS"]}[Data]
				in
				    Tbl
```

Use DirectQuery or Direct Lake (`mode: directLake` with an entity partition) only when the
spec or data volume demands it; state the trade-off.

## Dimension with hierarchy and sort-by

```tmdl
table Customer

	column CustomerKey
		dataType: int64
		isHidden
		isKey
		sourceColumn: CUSTOMER_KEY
		summarizeBy: none

	column 'Customer Name'
		dataType: string
		sourceColumn: CUSTOMER_NAME
		summarizeBy: none

	column Region
		dataType: string
		sourceColumn: REGION
		summarizeBy: none

	column Country
		dataType: string
		sourceColumn: COUNTRY
		summarizeBy: none

	hierarchy Geography
		level Region
			column: Region
		level Country
			column: Country
		level Customer
			column: 'Customer Name'
```

Bucket labels need a numeric sort column:

```tmdl
	column 'Aging Bucket'
		dataType: string
		sourceColumn: AGING_BUCKET
		sortByColumn: 'Aging Bucket Order'
		summarizeBy: none

	column 'Aging Bucket Order'
		dataType: int64
		isHidden
		sourceColumn: AGING_BUCKET_ORDER
		summarizeBy: none
```

## Date table

Prefer a date dimension from the warehouse. Mark it as a date table with
`dataCategory: Time` and a unique `isKey` date column:

```tmdl
table Date
	dataCategory: Time

	column Date
		dataType: dateTime
		isKey
		formatString: yyyy-mm-dd
		sourceColumn: DATE
		summarizeBy: none

	column DateKey
		dataType: int64
		isHidden
		sourceColumn: DATE_KEY
		summarizeBy: none

	column 'Month Start'
		dataType: dateTime
		formatString: mmm yyyy
		sourceColumn: MONTH_START
		summarizeBy: none

	column 'Fiscal Year'
		dataType: string
		sourceColumn: FISCAL_YEAR
		summarizeBy: none
```

If no warehouse date table exists, create a calculated table with DAX (covering whole years
of the fact data):

```dax
Date =
VAR MinD = DATE ( YEAR ( MIN ( 'AR Open Items'[SnapshotDate] ) ), 1, 1 )
VAR MaxD = DATE ( YEAR ( MAX ( 'AR Open Items'[SnapshotDate] ) ), 12, 31 )
RETURN
ADDCOLUMNS (
    CALENDAR ( MinD, MaxD ),
    "DateKey", YEAR ( [Date] ) * 10000 + MONTH ( [Date] ) * 100 + DAY ( [Date] ),
    "Month Start", DATE ( YEAR ( [Date] ), MONTH ( [Date] ), 1 ),
    "Year", YEAR ( [Date] ),
    "Month", FORMAT ( [Date], "MMM" ),
    "Month Number", MONTH ( [Date] )
)
```

## Measures table

```tmdl
table _Measures

	/// Sum of open receivable balance at the latest snapshot in the filter context.
	measure 'Total AR' =
			VAR LastSnap = LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'AR Open Items' ) ) )
			RETURN CALCULATE ( SUM ( 'AR Open Items'[OpenAmount] ), LastSnap )
		formatString: \$#,0;(\$#,0);\$#,0
		displayFolder: 01 Balances

	column Dummy
		dataType: string
		isHidden
		sourceColumn: Dummy
		summarizeBy: none

	partition _Measures = calculated
		mode: import
		source = ROW ( "Dummy", BLANK () )
```

## Relationships (relationships.tmdl)

Relationship names can be any unique identifier (Desktop uses GUIDs).

```tmdl
relationship ar_customer
	fromColumn: 'AR Open Items'.CustomerKey
	toColumn: Customer.CustomerKey

relationship ar_snapshot_date
	fromColumn: 'AR Open Items'.SnapshotDateKey
	toColumn: Date.DateKey

relationship ar_due_date
	isActive: false
	fromColumn: 'AR Open Items'.DueDateKey
	toColumn: Date.DateKey
```

`from` is the many side (fact), `to` is the one side (dimension). Add
`crossFilteringBehavior: bothDirections` only with a written reason.

## Row-level security (roles/)

```tmdl
role 'BU Managers'
	modelPermission: read

	tablePermission 'Business Unit' = 'Business Unit'[Manager Email] = USERPRINCIPALNAME ()
```

For a mapping table pattern (user → many BUs), filter a `Security` table and relate it to the
dimension; document that role membership is assigned in the Power BI Service.
