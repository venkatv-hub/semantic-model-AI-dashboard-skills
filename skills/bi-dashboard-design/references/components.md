# Component Specifications

Each component lists its anatomy, defaults and how it maps to each platform. Component ids
(`kpi_card`, `trend_line`, …) are the values used in `dashboard-spec.md`.

## Contents
1. kpi_card
2. trend_line
3. ranked_bar
4. variance_bar / bullet
5. waterfall
6. stacked_bar
7. matrix
8. exception_table
9. aging_buckets
10. funnel
11. map
12. slicer / filter
13. text / header

---

## 1. kpi_card
- **Anatomy:** label (top, 11–12 pt), value (24–32 pt, abbreviated), comparison line
  ("vs Budget +4.2% ▲"), optional sparkline (last 13 periods), optional status dot.
- **Defaults:** comparison required on L1; status color only if a target/threshold exists;
  the arrow shows direction of change, the color shows good/bad (they can disagree — e.g. DSO
  ▼ in green).
- **Power BI:** new Card visual (multi-card with reference labels) or KPI visual for trend +
  target.
- **Tableau:** BAN sheet — text mark with measure, delta calc and arrow calc; sparkline as a
  separate small line sheet stacked in a vertical container.
- **Looker:** `single_value` element with `comparison_type: change` (or `progress` vs
  target) and `comparison_reverse_colors: true` when lower is better.

## 2. trend_line
- **Anatomy:** time on x (continuous), measure on y, actual solid, comparison dashed and
  muted, label on last point, no legend if ≤ 2 series (label lines directly).
- **Defaults:** 13 months for monthly KPIs (shows same month last year), 12 weeks for weekly
  operations, y-axis starts at zero for amounts; ratios may use a fitted axis.
- **Power BI:** line chart, analytics pane constant/target line or a target measure series.
- **Tableau:** line with continuous MONTH(Date), reference line from target measure.
- **Looker:** `looker_line`, target as a second measure with dashed series style.

## 3. ranked_bar
- Horizontal bars sorted descending, top 10 + "Other" bucket, data labels at bar end, no
  gridlines. Highlight the selected/at-risk bar with the accent or status color.

## 4. variance_bar / bullet
- **Variance bar:** bar = actual − target per category, diverging around zero; positive
  colored "good" only if higher is better for that metric.
- **Bullet:** actual bar over a target tick and qualitative bands; best for many targets on
  one view (e.g. budget vs actual by cost center).

## 5. waterfall
- Start total (budget or prior year) → driver bars → end total (actual). Sort drivers by
  absolute size, group the long tail into "Other". Power BI has a native waterfall; Tableau uses
  a Gantt bar with size = −measure and a running sum; Looker uses `looker_waterfall` (or a
  custom viz if not enabled).

## 6. stacked_bar
- Use for mix (e.g. spend by category per quarter). ≤ 5 segments, consistent segment order
  and color across all charts. Prefer 100% stacked when share matters more than size.

## 7. matrix
- Rows = hierarchy (expandable), columns = time or scenario (Actual, Budget, Var, Var %).
- Conditional formatting on the variance column only; totals visible; freeze row headers.
- Power BI matrix; Tableau text table with highlight on one measure; Looker `looker_grid`
  with subtotals and pivots.

## 8. exception_table
- 5–7 columns: identifier, owner, key amount, key age/delay, status, a "why flagged" column.
- Sorted by severity (amount × age, or a severity score measure).
- Row icon or colored status text, never full-row background color.
- Provides drill-through or a URL action to the source record (ERP/CRM/EHR) if available.

## 9. aging_buckets
- Fixed bucket order: Current, 1–30, 31–60, 61–90, 91–120, 120+ (domain skills may change
  the edges). Color ramps from neutral to the bad color as age grows.
- Buckets must be a sorted dimension with an explicit sort key, never alphabetical.

## 10. funnel
- Stages in process order with stage-to-stage conversion %. Use a bar-based funnel (aligned
  left) for readability; avoid 3D or trapezoid shapes.

## 11. map
- Only when the user acts by location (sites, territories). Filled map for regions, sized
  points for facilities. Always pair with a ranked bar so values can be read precisely.

## 12. slicer / filter
- Period, organization (BU/region), and one domain dimension at most on L1. L3 pages may add
  many. Use dropdowns for > 7 values, button slicers for ≤ 5.

## 13. text / header
- Title (18–20 pt), subtitle with scope/period/currency/as-of (10–11 pt, muted), optional
  logo right-aligned at small size. Footer with definitions link and owner.
