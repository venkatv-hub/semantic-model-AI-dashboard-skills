# Tableau Dashboard Layout, Actions and Build Sheet

## Container plan

Build every dashboard from containers so it stays aligned when sheets change:

```
Dashboard (Fixed 1366 x 768), outer padding 16
└─ Vertical container (tiled)
   ├─ Horizontal container: Header  [Title text | Subtitle text (as-of, currency) | filters]
   ├─ Horizontal container: KPI row  [BAN 1 | BAN 2 | BAN 3 | BAN 4 | BAN 5 | BAN 6] (distribute evenly)
   ├─ Horizontal container: Row 2    [Trend (8/12 width) | Breakdown (4/12)]
   ├─ Horizontal container: Row 3    [Variance (6/12) | Exceptions (6/12)]
   └─ Horizontal container: Footer   [Definitions button | Refresh timestamp]
```

- Use "Distribute contents evenly" on KPI rows; fix the KPI row height (~110 px).
- Remove sheet titles from inside sheets when the dashboard has a header text; otherwise
  give each sheet a question-style title.
- Hide legends unless color carries meaning; put color meaning in the title
  ("Below target in red").
- Floating objects only for small overlays (info icon, reset button).

## Actions

| Action | Use |
|---|---|
| Filter action (select) | L1 breakdown → L2 detail sheets; target the sheets, not the whole dashboard |
| Highlight action (hover) | Linked charts on the same page |
| Go to Sheet / navigation | Buttons between L1, L2 and L3 dashboards |
| URL action | Exception table row → source system record (ERP, CRM, EHR) |
| Set / parameter action | Interactive Top N, scenario selection, "select a month to compare" |

"Clearing the selection will": show all values (L1), keep filtered values (L3 detail).

## Reset

Add a navigation button that reloads the same dashboard, or a parameter-action reset that
returns parameters to defaults. Document that filters persist per user session in Tableau
Cloud/Server unless "Reset view" is used.

## Mobile layout

Add a phone device layout: header, KPI BANs stacked 2-per-row, primary trend, exceptions
table limited to top 10.

## Build sheet (mode C)

```
DATA SOURCE: AR Collections (published) — fields/calcs listed in calc sheet
DASHBOARD: AR Overview — fixed 1366x768, palette "BI Domain Skills Neutral"

SHEET | Marks | Columns | Rows | Color | Label | Filters | Notes
BAN Total AR | Text | – | – | – | Total AR, Delta label | Period, BU | Font 28pt
DSO Trend | Line | MONTH(Snapshot Date) cont. | DSO | – | last point | last 13 months | Ref line: DSO Target
Aging | Bar | Aging Bucket (sorted by order calc) | Total AR | Bucket ramp | value | – |
...
ACTIONS: Filter (select) Aging → Exceptions; URL Exceptions → ERP invoice link
```

Close with the list of calculated fields (name, folder, formula, comment) ready to create.
