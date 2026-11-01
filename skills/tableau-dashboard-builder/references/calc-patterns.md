# Tableau Calculation Patterns

Replace field names with the data source's captions. Start every calc with a `//` comment
that restates the domain definition.

## 1. Base and ratios

```
// Gross margin % = gross margin / revenue
SUM([Gross Margin]) / SUM([Revenue])
```

Guard divide-by-zero only when needed: `IF SUM([Revenue]) = 0 THEN NULL ELSE ... END`.

## 2. Period comparisons without table calcs

Driven by a date parameter or the max date in the data. Table-calc versions break when the
prior period is filtered out of the view, so prefer these "period flag" calcs:

```
// Anchor date: latest complete month in the data
DATETRUNC('month', {FIXED : MAX([Posting Date])})

// Revenue current month
SUM(IF DATETRUNC('month',[Posting Date]) = DATEADD('month', -1, [Anchor Month]) THEN [Amount] END)

// Revenue same month prior year
SUM(IF DATETRUNC('month',[Posting Date]) = DATEADD('month', -13, [Anchor Month]) THEN [Amount] END)

// Revenue YTD (calendar)
SUM(IF YEAR([Posting Date]) = YEAR([Reporting Month]) AND [Posting Date] <= [Reporting Month End] THEN [Amount] END)

// YoY %
([Revenue CM] - [Revenue PY CM]) / ABS([Revenue PY CM])
```

Adjust `[Anchor Month]` logic to the domain's "latest closed period" rule; when the user
picks a period via a parameter, replace the anchor with the parameter.

For trend lines across many periods, a table calc is fine:
`(ZN(SUM([Revenue])) - LOOKUP(ZN(SUM([Revenue])), -12)) / ABS(LOOKUP(ZN(SUM([Revenue])), -12))`
with compute using the date axis, and the view must include ≥ 13 months.

## 3. Snapshot (semi-additive) measures

Balances (AR, AP, inventory, headcount, open pipeline) must never be summed across
snapshot dates.

```
// Is period-end snapshot: the last snapshot date in each month
[Snapshot Date] = {FIXED DATETRUNC('month',[Snapshot Date]) : MAX([Snapshot Date])}

// Inventory on hand (period-end)
SUM(IF [Is Period-End Snapshot] THEN [On Hand Value] END)
```

This works on trends by month and on KPI cards filtered to one month. For a KPI card that
must show the latest balance within any selected date range, use:

```
// Is latest snapshot in the selected range (make the date filter a CONTEXT filter)
[Snapshot Date] = {FIXED : MAX([Snapshot Date])}
```

and make the period filter a context filter so the FIXED expression respects it.

## 4. LOD expressions

```
// Customer first order date
{FIXED [Customer ID] : MIN([Order Date])}

// Revenue per customer (respects dimension filters only if they are context filters)
{FIXED [Customer ID] : SUM([Revenue])}

// Share of region total in a view at customer level
SUM([Revenue]) / SUM({EXCLUDE [Customer Name] : SUM([Revenue])})
```

Filter order: extract → data source → context → FIXED LOD → dimension filters → INCLUDE/
EXCLUDE → measure filters → table calcs. If a FIXED calc must react to a dashboard filter,
make that filter a context filter.

## 5. Buckets

```
// Aging bucket
IF [Days Past Due] <= 0 THEN "Current"
ELSEIF [Days Past Due] <= 30 THEN "1-30"
ELSEIF [Days Past Due] <= 60 THEN "31-60"
ELSEIF [Days Past Due] <= 90 THEN "61-90"
ELSE "90+" END
```

## 6. Top N + Other

Create a set `Top Customers` (Top N by `SUM([Revenue])` using `[Top N]` parameter), then:

```
// Customer (Top N + Other)
IF [Top Customers] THEN [Customer Name] ELSE "Other" END
```

Sort by `SUM([Revenue])` descending and pin "Other" last with a sort-helper calc
`IF [Top Customers] THEN 0 ELSE 1 END`.

## 7. Display helpers

```
// Delta label
IF ISNULL([Revenue YoY %]) THEN "–"
ELSE (IF [Revenue YoY %] >= 0 THEN "▲ +" ELSE "▼ " END) + STR(ROUND([Revenue YoY %]*100,1)) + "% vs PY"
END

// Status (lower is better example, target 45)
IF [DSO] <= 45 THEN "Good" ELSEIF [DSO] <= 49.5 THEN "Watch" ELSE "Off track" END
```

Map `Good`/`Watch`/`Off track` to the semantic colors on the color shelf and keep the mapping
identical on every sheet.

## 8. Verification
- Build a text table with Measure Names/Values by month; compare totals with a SQL query on
  the source for the same filters.
- Toggle each dashboard filter and confirm FIXED-based KPIs change when they should.
- Check the latest period is not NULL for every L1 KPI.
