# Tableau Data Model and .tds XML

## Relationships vs joins

- **Relationships (logical layer)** – default. Tables keep their native grain; Tableau
  generates the right join at query time. Use for fact ↔ dimension and fact ↔ fact on shared
  keys.
- **Joins (physical layer)** – inside a single logical table, only when tables share grain
  (e.g. invoice header + invoice attributes 1:1). Joins that fan out duplicate measures.
- **Performance options** on each relationship: set cardinality (many-to-one) and referential
  integrity ("all records match") when true; it lets Tableau drop unnecessary joins.

Multi-fact pattern (actuals + budget): two logical fact tables, each related to shared
dimension tables (Date month, Cost Center, Account). If Tableau's multi-fact relationships are
not available in the user's version, relate budget to actuals on the composite key of shared
dimensions and test totals carefully.

## Recommended workflow for the file

1. User connects in Tableau Desktop, drags the tables into the relationship canvas, saves the
   data source as `.tds` (Data ▸ <source> ▸ Add to Saved Data Sources) or downloads the
   published one.
2. Agent edits the `.tds` to add semantics (below), keeping the `<connection>` element
   untouched.
3. User opens it in Desktop, checks for errors, publishes.

## Calculated field

```xml
<column caption='Total AR' datatype='real' name='[Calculation_TotalAR]' role='measure' type='quantitative'
        default-format='c&quot;$&quot;#,##0;(&quot;$&quot;#,##0)'>
  <calculation class='tableau' formula='// Open receivable balance at the period-end snapshot&#10;SUM(IF [Is Period-End Snapshot] THEN [Open Amount] END)' />
  <desc>
    <formatted-text><run>Open receivable balance at the last snapshot of each period (see Is Period-End Snapshot).</run></formatted-text>
  </desc>
</column>
```

XML escaping inside `formula`: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `'` → `&apos;`
(the attribute uses single quotes), `"` → `&quot;`, newline → `&#10;`. Calc `name` values
must be unique and bracketed; captions are what users see.

Field references in formulas use the field caption in brackets (`[Open Amount]`). If a
caption is ambiguous across tables, use the internal name `[OPEN_AMOUNT (FCT_AR_OPEN_ITEMS)]`
as shown in the existing `.tds`.

## Renaming, hiding and formatting existing fields

```xml
<column caption='Customer Name' datatype='string' name='[CUSTOMER_NAME]' role='dimension' type='nominal' />
<column datatype='integer' hidden='true' name='[CUSTOMER_KEY]' role='dimension' type='ordinal' />
<column caption='Open Amount' datatype='real' name='[OPEN_AMOUNT_USD]' role='measure' type='quantitative'
        aggregation='Sum' default-format='c&quot;$&quot;#,##0' />
```

## Folders

```xml
<folder name='01 Balances' role='measures'>
  <folder-item name='[Calculation_TotalAR]' type='field' />
  <folder-item name='[Calculation_OverduePct]' type='field' />
</folder>
```

## Hierarchies (drill paths)

```xml
<drill-paths>
  <drill-path name='Geography'>
    <field>[REGION]</field>
    <field>[COUNTRY]</field>
    <field>[CUSTOMER_NAME]</field>
  </drill-path>
</drill-paths>
```

## Sort order for buckets

Create a calc `Aging Bucket Order` (1–5) and set the bucket dimension's default sort to
"Field ▸ Aging Bucket Order ▸ Minimum" in Desktop, or keep a manual sort in each sheet.

## Parameters

```xml
<column caption='Top N' datatype='integer' name='[Parameter_TopN]' param-domain-type='range' role='measure' type='quantitative' value='10'>
  <calculation class='tableau' formula='10' />
  <range granularity='1' max='50' min='5' />
</column>
```

Parameters live in a datasource named `Parameters` in a `.twb`; in a published `.tds` keep
parameter-dependent calcs in the workbook unless the user's Tableau version supports
parameters in published sources.

## Row-level security

Preferred: a user/entitlement table related to the fact on the secured dimension, plus a data
source filter calc `USERNAME() = [User Email]` (or `ISMEMBEROF('Group')`). Publish with the
filter as a data source filter so it cannot be removed in workbooks. Tableau Cloud virtual
connections with data policies are the stronger option when available.
