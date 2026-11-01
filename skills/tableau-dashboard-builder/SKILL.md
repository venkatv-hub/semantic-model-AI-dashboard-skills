---
name: tableau-dashboard-builder
description: Builds Tableau dashboards and published data sources from a dashboard spec — relationship-based data models, calculated fields and LOD expressions, .tds/.twb XML, dashboard layout containers, actions, parameters, and Tableau Next semantic models. Use this skill whenever the user wants a Tableau or Tableau Next dashboard, workbook, data source, calculated fields or LOD calcs built or changed, including when a domain skill (finance, supply chain, healthcare, sales, HR) has produced a dashboard spec and the target platform is Tableau, Tableau Cloud, Tableau Server or Tableau Next.
---

# Tableau Dashboard Builder

Turns a dashboard spec (see `bi-dashboard-design/references/dashboard-spec.md`) into Tableau
artifacts. Domain definitions come from the domain skill; layout and styling rules from
`bi-dashboard-design`.

## Choose the build mode first

| Mode | When | What you produce |
|---|---|---|
| **A. Tableau MCP / APIs** | Tableau MCP server or REST/Metadata API access is available | Query and validate against the published data source; publish updated `.tds`/`.twb` via API if permitted |
| **B. XML files** | You can write files | A published data source `.tds` (calcs, folders, hierarchies, captions, descriptions) and optionally a `.twb` with worksheets and a dashboard |
| **C. Build kit** | Chat only, or the user prefers to build in Desktop | Calculated field list (name, formula, description, folder), sheet-by-sheet build sheet, dashboard container plan, palette XML |
| **D. Tableau Next** | Target is Tableau Next on Salesforce | Semantic model definitions (data objects, relationships, calculated measurements/dimensions, metrics) and a dashboard plan; see `references/tableau-next.md` |

Recommended in practice: **let Tableau create the connection, let the agent add the
semantics.** Ask the user to connect to the tables in Tableau Desktop and save a `.tds` (or
download the published source). Then add calculated fields, folders, hierarchies, captions,
default formats and comments to that file. Hand-writing connection XML from scratch is fragile
because connection attributes differ per database and driver version.

## Workflow

1. **Read the spec and the domain metrics file.** Each calc must match a domain definition.
2. **Model the data source** (`references/data-model.md`):
   - Use relationships (the logical layer) between fact and dimension tables; use physical
     joins only inside a logical table when the grain is identical.
   - Multiple facts at different grains (e.g. actuals and budget) are separate logical tables
     related on shared dimension keys, or a multi-fact relationship model if supported.
   - Rename fields to business names, hide keys, set default number formats and aggregation,
     create hierarchies matching the domain drill path, group fields into folders.
3. **Write calculations** (`references/calc-patterns.md`): aggregate calcs for KPIs, LOD for
   fixed-grain logic (first purchase date, customer-level aggregates), table calcs only for
   display (running totals, rank, % of total). Put a comment in every calc (`// definition`).
4. **Build sheets and the dashboard** (`references/dashboard-layout.md`): one worksheet per
   spec component, then a fixed-size dashboard assembled from tiled containers following the
   12-column grid; add filter, highlight and navigation actions; add a "reset" button.
5. **Publish or hand over:** publish the data source first, then the workbook connected to
   the published source, so metrics are reused across workbooks.
6. **Verify:** compare totals against SQL, confirm LODs behave with dashboard filters
   (context filters where needed), then run the `bi-dashboard-design` acceptance checklist.

## Grid mapping

- Default fixed size 1366 × 768 (laptop) or 1600 × 900 (large screens); mobile layout as a
  separate device layout with KPIs stacked.
- Outer padding 16 px; tiled horizontal containers per spec row; each component's width =
  `cols/12` of the row (set fixed widths in pixels for KPI tiles so they line up).
- One height unit ≈ 56 px.

## Visual mapping

| Spec component | Tableau build |
|---|---|
| kpi_card | BAN: text mark with measure + delta + arrow calc; optional sparkline sheet below |
| trend_line | Line with continuous MONTH(date); target as reference line or dual line (synchronized axis) |
| ranked_bar | Horizontal bar sorted descending, Top N set + "Other" via set calc |
| variance_bar | Bar on variance calc, color on a good/bad calc that respects direction |
| waterfall | Gantt bar: running sum of measure, size = −measure |
| stacked_bar | Stacked bar with consistent color order |
| matrix | Text table with Measure Names columns; highlight table only on one measure |
| exception_table | Text table, sorted by severity calc, URL action to source system |
| aging_buckets | Bar on bucket dimension with manual sort |
| funnel | Bar sorted by stage order, conversion % label via table calc |
| map | Filled map with a ranked bar beside it |
| slicer | Quick filters (single value dropdown / multiple value dropdown), applied to related sheets |

## Guardrails
- Use `ZN()` and `IFNULL()` deliberately; a blank should usually remain blank on KPI cards.
- Ratios are `SUM(numerator)/SUM(denominator)`, never `AVG([ratio])`.
- Don't use FIXED LODs for KPIs that must respect dashboard filters unless those filters are
  context filters — explain this to the user when it matters.
- Avoid data blending when relationships can model it.
- Do not embed credentials in files you share; leave authentication to publishing.

## Reference files
- `references/data-model.md` – relationships, multi-fact patterns, .tds XML for calcs,
  folders, hierarchies.
- `references/calc-patterns.md` – period comparisons, snapshots, LODs, buckets, top N,
  display helpers.
- `references/dashboard-layout.md` – container plan, actions, parameters, build-sheet format.
- `references/tableau-next.md` – Tableau Next semantic model and dashboard notes.
