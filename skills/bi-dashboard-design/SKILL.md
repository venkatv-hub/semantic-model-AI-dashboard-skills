---
name: bi-dashboard-design
description: Shared design system for business dashboards in Power BI, Tableau and Looker — page layout grid, level-of-detail tiers (executive, manager, analyst), KPI card anatomy, chart selection, color, number formatting, filters, drill paths and accessibility. Use this skill whenever you design, plan, critique or build any BI dashboard or report page, write a dashboard spec, or choose visuals for KPIs, even if the user only says "make a dashboard" or names a domain like finance, supply chain, healthcare, sales or HR. Domain skills in this repo depend on it.
---

# BI Dashboard Design System

This skill is the shared foundation for every domain skill in this repository. Domain skills
(for example `finance-ar-collections-dashboard`) decide **what** to show; this skill decides
**how** it should look and behave, so every dashboard built from this repo feels like it came
from the same professional team, whichever BI tool it lands in.

## How this skill fits the workflow

Every dashboard follows the same four steps. Do them in order and do not skip the spec.

1. **Frame** – confirm the audience tier, the decisions the dashboard supports, the BI platform
   (Power BI, Tableau, or Looker) and where the data lives. Ask at most three questions; use
   sensible defaults for anything else and state them.
2. **Spec** – write a dashboard spec in the format in `references/dashboard-spec.md`. Show it to
   the user before building. A spec is cheap to change; a built report is not.
3. **Build** – implement the spec with the platform builder skill:
   `powerbi-dashboard-builder`, `tableau-dashboard-builder` or `looker-dashboard-builder`.
4. **Verify** – run the acceptance checklist at the end of this file and report anything that
   could not be met (missing data, unsupported visual, assumptions made).

## Level-of-detail tiers

Pick one tier per page. Mixing tiers on a single page is the most common reason dashboards
feel cluttered. A dashboard usually has one L1 page, one to three L2 pages, and L3 pages
reached by drill-through.

| Tier | Audience | Question it answers | Content | Visual budget |
|---|---|---|---|---|
| **L1 Executive** | C-suite, VP, board | "Are we on track, and where is the problem?" | 4–6 KPI cards with target/prior comparison, 1–2 trends, 1 breakdown, top exceptions | ≤ 8 visuals, no raw tables |
| **L2 Manager** | Function heads, BU owners | "Which segment, region, product or owner is driving it?" | Breakdowns by 2–4 dimensions, variance analysis, ranked lists, exception tables | ≤ 12 visuals |
| **L3 Analyst / Operational** | Analysts, operators, collectors, planners | "Which exact records need action?" | Detail tables, drill-through record view, export, many filters | Tables first; charts only for context |

Rules of thumb:
- L1 pages answer in five seconds; if a viewer must hover or click to get the headline, move it.
- Every L1 number needs a comparison (target, budget, prior period or prior year). A number with
  no comparison is trivia.
- L3 pages are reached through drill-through or a "details" link, not by default navigation.

## Page layout

Design on an abstract **12-column grid** in the spec; each builder skill maps it to the
platform (Power BI 1280×720 canvas, Tableau fixed 1366×768 or 1600×900, Looker newspaper
layout of 24 columns — multiply column spans by 2).

Standard L1 layout, top to bottom (the "F-pattern": the eye lands top-left first):

```
Row 0  | Title + subtitle (as-of date, currency, scope)            | Global filters (right) |
Row 1  | KPI | KPI | KPI | KPI | KPI | KPI    (each 2 cols, height 2 units)               |
Row 2  | Primary trend (8 cols, h4)                     | Breakdown / mix (4 cols, h4)    |
Row 3  | Variance or ranked bar (6 cols, h4)  | Exceptions / top-N table (6 cols, h4)    |
Footer | Definitions link · data refresh timestamp · owner                                 |
```

- Most important KPI goes top-left. Order KPI cards by the story: outcome → drivers → health.
- Keep consistent gutters (16 px Power BI / 8 px Tableau padding) and align edges on the grid.
- Put filters in one place per page (top bar or left rail), never scattered between visuals.
- Always show **data as-of / last refresh** time and the **currency/unit** in the header.

## Component library

Full specs for each component are in `references/components.md`. Summary:

| Component | Use for | Key rules |
|---|---|---|
| **KPI card** | Headline metric | Value, label, comparison delta (abs and %), direction arrow, status color only when a target exists, optional 13-month sparkline |
| **Trend line** | Change over time | Time on x-axis, ≤ 4 series, show target/PY as a dashed reference line, label last point |
| **Bar (ranked)** | Compare categories | Horizontal, sorted descending, ≤ 10 bars plus "Other", data labels instead of gridlines |
| **Variance bar / bullet** | Actual vs target | Diverging color around zero; bullet chart for many targets |
| **Waterfall** | Bridge from A to B (budget → actual, PY → CY) | Start and end totals anchored, drivers sorted by magnitude |
| **Stacked/100% bar** | Mix and composition | ≤ 5 segments; never pies with more than 3 slices |
| **Matrix / heat table** | Two-dimensional comparison | Conditional formatting on one measure only, totals row and column |
| **Exception table** | Records needing action | ≤ 7 columns, sorted by severity, row-level status icon, link to drill-through |
| **Aging buckets** | AR/AP/inventory age | Fixed bucket order left to right (Current → 90+), never sorted by value |
| **Map** | Only when location drives action | Filled map for regions, points for sites; never as decoration |
| **Funnel** | Staged conversion | Stages in process order, show conversion % between stages |

Chart selection guidance with anti-patterns is in `references/chart-selection.md`.

## Color

- Neutral canvas (white or very light gray), dark gray text (#252423 range), one brand accent
  for "current period" data.
- Semantic status colors are reserved for status: good (green #1A7F37), warning (amber
  #B7791F), bad (red #C62828). Never use them as decorative series colors.
- Use a colorblind-safe categorical palette for series (blue #2563EB, orange #EA580C, teal
  #0D9488, purple #7C3AED, gray #6B7280). Never encode meaning with color alone — pair it with
  an icon, arrow or label.
- Comparison series (prior year, budget) are a lighter tint or gray of the actual series.
- A starter theme with these tokens is in `references/theme-tokens.md`; builder skills convert
  it into a Power BI theme JSON, Tableau custom palette and Looker dashboard styling.

## Number formatting

| Kind | Format | Example |
|---|---|---|
| Currency on cards | Abbreviated, 1 decimal above 1K | $4.2M |
| Currency in tables | Full with thousands separator, no decimals | $4,215,880 |
| Percent | 1 decimal | 37.4% |
| Percentage-point change | "pp" suffix | +2.1 pp |
| Ratios (turns, coverage) | 1–2 decimals with unit | 6.3x |
| Days | Integer + "days" or "d" | 47 d |
| Counts | Thousands separator | 12,480 |

- Deltas show a sign (+/−). Decide "higher is better" per metric (the domain skill tells you)
  and color the delta accordingly — a falling DSO is good, a falling revenue is bad.
- Never show more precision than the business acts on.

## Titles and text

- Visual titles state the question or the insight: "Revenue vs budget by region" or
  "3 regions below budget" — not "Chart 1" or a field name.
- Every page has a one-line subtitle: scope, period, currency and as-of date.
- Use business names from the semantic model, not database column names (`Net Revenue`, not
  `NET_REV_AMT`).
- Put metric definitions in tooltips or an info page, not on the canvas.

## Filters, interactions and drill paths

- Global filters (period, business unit/region, currency) at page top; local filters inside
  the visual header if the platform supports it.
- Default the period filter to the latest complete period (e.g. last closed month for
  finance), never "all time".
- Cross-filtering: on for L2 pages; on L1 restrict it so clicking a breakdown does not blank
  the KPI cards unexpectedly.
- Drill paths go from summary to detail along the natural hierarchy the domain skill defines
  (e.g. Region → Country → Customer → Invoice). Expose them as drill-down in hierarchies plus a
  drill-through to the L3 record page.
- Provide a "reset filters" control (bookmark/button in Power BI, reset action in Tableau,
  default filter values in Looker).

## Accessibility and performance

- Text contrast at least 4.5:1; minimum font 11 pt for labels and 9 pt for axis ticks.
- Every visual has alt text (Power BI) or a caption/description (Tableau, Looker).
- Logical tab order top-left to bottom-right.
- Keep visual count within the tier budget; high-cardinality tables use paging or top-N.
- Push calculations into the semantic layer (measures, LookML, published data source calcs),
  never into visual-level quick calcs that cannot be reused.

## Acceptance checklist

Before declaring a dashboard done, confirm each item and report any that fail:

- [ ] Each page has exactly one LOD tier and stays within its visual budget.
- [ ] Every L1 KPI shows a comparison and uses the right "higher is better" direction.
- [ ] Status colors appear only where a target or threshold exists.
- [ ] Header shows scope, period, currency/unit and data refresh time.
- [ ] Metric definitions match the domain skill's `<domain-skill>/references/metrics.md` exactly.
- [ ] Default filters show the latest complete period.
- [ ] Drill path from L1 to L3 works for at least the primary KPI.
- [ ] Measures live in the semantic layer and are documented (description per measure).
- [ ] Sensitive data (PII/PHI, salaries) is masked or aggregated and row-level security is
      described when the domain requires it.
- [ ] Alt text / descriptions are present and contrast passes.

## Reference files

- `references/dashboard-spec.md` – the spec format every domain skill produces. Read before
  writing a spec.
- `references/components.md` – detailed anatomy of each component.
- `references/chart-selection.md` – which chart for which question, and what to avoid.
- `references/theme-tokens.md` – color, font and spacing tokens to turn into platform themes.
