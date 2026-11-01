# DAX Patterns

Reusable patterns. Replace table and column names with the model's. Every measure needs a
format string and a description.

## Contents
1. Base and ratio measures
2. Time intelligence
3. Semi-additive (snapshot) measures
4. Role-playing dates
5. Targets and budgets
6. Buckets and bands
7. Top N + Other
8. Display helpers (delta, arrow, status color, dynamic titles)
9. Field parameters
10. Verification

## 1. Base and ratio measures

```dax
Revenue = SUM ( 'GL Lines'[AmountUSD] )

Gross Margin % = DIVIDE ( [Gross Margin], [Revenue] )
```

Ratios are always computed from aggregated numerator and denominator. Never `AVERAGEX` a
ratio column unless the definition explicitly says "average of".

## 2. Time intelligence

Requires a marked Date table.

```dax
Revenue PY = CALCULATE ( [Revenue], SAMEPERIODLASTYEAR ( 'Date'[Date] ) )

Revenue YTD = TOTALYTD ( [Revenue], 'Date'[Date] )
-- Fiscal year ending June 30:
Revenue FYTD = TOTALYTD ( [Revenue], 'Date'[Date], "06-30" )

Revenue PM = CALCULATE ( [Revenue], DATEADD ( 'Date'[Date], -1, MONTH ) )

Revenue YoY % = DIVIDE ( [Revenue] - [Revenue PY], [Revenue PY] )

Revenue Rolling 12M =
CALCULATE (
    [Revenue],
    DATESINPERIOD ( 'Date'[Date], MAX ( 'Date'[Date] ), -12, MONTH )
)
```

Latest complete period (for default filters and "as-of" titles):

```dax
Last Closed Month End =
VAR LastData = CALCULATE ( MAX ( 'GL Lines'[PostingDate] ), REMOVEFILTERS () )
RETURN EOMONTH ( LastData, IF ( LastData = EOMONTH ( LastData, 0 ), 0, -1 ) )
```

For 13-month trend visuals, add a `Date` column flag computed in the warehouse or Power
Query (`IsInLast13Months`) and use it as a visual filter; this is faster than a measure
filter.

## 3. Semi-additive (snapshot) measures

Balances (AR, AP, inventory on hand, headcount, open pipeline) must not be summed across
time. Take the last snapshot in context:

```dax
Inventory On Hand Value =
CALCULATE (
    SUM ( 'Inventory Snapshot'[OnHandValue] ),
    LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'Inventory Snapshot' ) ) )
)

Average Inventory Value (period) =
AVERAGEX (
    VALUES ( 'Date'[Month Start] ),
    CALCULATE ( [Inventory On Hand Value] )
)
```

## 4. Role-playing dates

```dax
Invoices Due = CALCULATE ( [Invoice Amount], USERELATIONSHIP ( 'AR Open Items'[DueDateKey], 'Date'[DateKey] ) )
```

## 5. Targets and budgets

Budgets are usually at month × cost center grain. Relate the budget fact to the same
`Date` (month start) and dimensions; when the budget grain is coarser than a dimension on the
visual, return blank instead of a misleading allocation:

```dax
Budget =
IF (
    ISINSCOPE ( Product[Product] ),   -- budget not set at product level
    BLANK (),
    SUM ( Budget[AmountUSD] )
)

Var vs Budget = [Revenue] - [Budget]
Var vs Budget % = DIVIDE ( [Var vs Budget], ABS ( [Budget] ) )
```

Constant targets that change rarely can live in a small `Targets` table (Metric, Value,
EffectiveFrom) and be read with `LOOKUPVALUE` or `CALCULATE ( MAX ( Targets[Value] ),
Targets[Metric] = "DSO" )`.

## 6. Buckets and bands

Prefer bucket columns from the warehouse. If computed in DAX (calculated column):

```dax
Aging Bucket =
SWITCH (
    TRUE (),
    'AR Open Items'[DaysPastDue] <= 0, "Current",
    'AR Open Items'[DaysPastDue] <= 30, "1-30",
    'AR Open Items'[DaysPastDue] <= 60, "31-60",
    'AR Open Items'[DaysPastDue] <= 90, "61-90",
    "90+"
)
```

and a matching `Aging Bucket Order` column used as sort-by.

## 7. Top N + Other

Use a disconnected table `TopN Customer` = `UNION ( VALUES ( Customer[Customer Name] ),
ROW ( "Customer Name", "Other" ) )` and:

```dax
Revenue Top N + Other =
VAR N = 10
VAR CurrentName = SELECTEDVALUE ( 'TopN Customer'[Customer Name] )
VAR Ranked =
    TOPN ( N, ALLSELECTED ( Customer[Customer Name] ), [Revenue] )
RETURN
IF (
    CurrentName = "Other",
    CALCULATE ( [Revenue], EXCEPT ( ALLSELECTED ( Customer[Customer Name] ), Ranked ) ),
    IF (
        CurrentName IN SELECTCOLUMNS ( Ranked, "n", Customer[Customer Name] ),
        CALCULATE ( [Revenue], Customer[Customer Name] = CurrentName )
    )
)
```

For simple cases, the visual-level Top N filter is acceptable on L2 pages.

## 8. Display helpers

```dax
Revenue vs PY Label =
VAR d = [Revenue YoY %]
RETURN IF ( ISBLANK ( d ), "–", FORMAT ( d, "+0.0%;-0.0%" ) & IF ( d >= 0, " ▲", " ▼" ) & " vs PY" )

-- 1 = good, 0 = neutral, -1 = bad. HigherIsBetter comes from the domain metrics file.
DSO Status =
VAR Target = 45
VAR v = [DSO]
RETURN SWITCH ( TRUE (), ISBLANK ( v ), 0, v <= Target, 1, v <= Target * 1.1, 0, -1 )

DSO Status Color = SWITCH ( [DSO Status], 1, "#1A7F37", 0, "#B7791F", -1, "#C62828" )

Page Subtitle =
"As of " & FORMAT ( [Last Closed Month End], "d mmm yyyy" ) & " · USD · " &
IF ( ISFILTERED ( 'Business Unit'[Business Unit] ), CONCATENATEX ( VALUES ( 'Business Unit'[Business Unit] ), 'Business Unit'[Business Unit], ", " ), "All business units" )
```

Use status color measures in conditional formatting ("Format style: Field value").

## 9. Field parameters

Use field parameters to let L2 users switch the breakdown dimension (Region / Product /
Channel) or the measure (Revenue / Margin / Units) without duplicating visuals. Create them in
Desktop (Modeling ▸ New parameter ▸ Fields); in TMDL they are calculated tables with
`NAMEOF()` rows and an `extendedProperty ParameterMetadata`. If generating by hand, copy the
structure from an existing parameter in the same project.

## 10. Verification

Run with DAX query view, the MCP `dax_query` tool, or `pbi dax execute`:

```dax
EVALUATE
SUMMARIZECOLUMNS (
    'Date'[Month Start],
    "Revenue", [Revenue],
    "Revenue PY", [Revenue PY],
    "GM %", [Gross Margin %]
)
ORDER BY 'Date'[Month Start] DESC
```

Checks:
- Grand total of each base measure equals a direct SQL total on the source for the same
  filter (state the SQL you used).
- The latest period is not blank for every L1 KPI.
- Snapshot measures do not grow when you widen the date range from one month to a year.
- Ratios at total level equal numerator total ÷ denominator total.
