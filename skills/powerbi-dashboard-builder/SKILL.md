---
name: powerbi-dashboard-builder
description: Builds Power BI semantic models and reports from a dashboard spec — star schema in TMDL (PBIP project format), DAX measures with time intelligence and semi-additive patterns, report pages in PBIR, themes, drill-through, field parameters and row-level security. Use this skill whenever the user wants a Power BI dashboard, report, semantic model, dataset, DAX measures or a .pbip project built or changed, including when a domain skill (finance, supply chain, healthcare, sales, HR) has produced a dashboard spec and the target platform is Power BI or Fabric.
---

# Power BI Dashboard Builder

Turns a dashboard spec (see `bi-dashboard-design/references/dashboard-spec.md`) into a working
Power BI artifact. Domain knowledge comes from the domain skill; layout and styling rules come
from `bi-dashboard-design`. This skill covers the Power BI specifics.

## Choose the build mode first

Check what is available and tell the user which mode you are using:

| Mode | When | What you produce |
|---|---|---|
| **A. Live model via MCP/CLI** | The Power BI Modeling MCP server (`@microsoft/powerbi-modeling-mcp`) or `pbi-cli` is connected and Power BI Desktop has the model open | Tables, relationships, measures created directly in the open model; report built as PBIR files |
| **B. PBIP project files** | You can write files but have no live connection | A `.pbip` project folder: `<Name>.SemanticModel/definition/*.tmdl` and `<Name>.Report/definition/` (PBIR) the user opens in Power BI Desktop |
| **C. Build kit** | Neither files nor tools are practical (e.g. chat-only) | DAX measure script, TMDL snippets, theme JSON and a page-by-page build sheet a developer follows |

Prefer A, then B. In mode B, remind the user to enable the PBIP save option and "Store
semantic model using TMDL format" in Power BI Desktop preview features if their version still
has them as previews.

## Workflow

1. **Read the spec and the domain metrics file.** Every measure you create must match a
   definition in the domain skill's `<domain-skill>/references/metrics.md`.
2. **Model the star schema** (`references/tmdl-patterns.md`):
   - One fact table per grain in the spec; dimensions conformed across facts.
   - A dedicated `Date` table marked as a date table, continuous, covering all fact dates,
     with fiscal columns when the domain uses a fiscal calendar.
   - Single-direction one-to-many relationships from dimension to fact. Use bidirectional
     only with a written reason. Role-playing dates (invoice vs due vs paid date): one active
     relationship, the others inactive and activated with `USERELATIONSHIP` in measures.
   - Hide foreign keys and raw numeric columns that are replaced by measures; set
     `summarizeBy: none` on keys, IDs and year/month numbers.
   - Sort-by columns for month names and for bucket labels (aging, bands).
3. **Write measures** (`references/dax-patterns.md`): a `_Measures` table, display folders per
   theme (e.g. `01 Revenue`, `02 Margin`), a format string and a description on every measure.
   Build base measures first, then ratios, then time intelligence, then display helpers
   (delta %, arrow, status color).
4. **Build report pages** (`references/report-pbir.md`): map each spec component to a visual,
   place it on the 1280×720 canvas using the grid mapping, apply the theme from
   `bi-dashboard-design/references/theme-tokens.md`, add drill-through pages and a reset
   bookmark.
5. **Security:** if the spec has `row_level`, create the RLS role with a DAX filter on the
   relevant dimension and document how to assign members in the Service.
6. **Verify:** run the DAX checks in `references/dax-patterns.md#verification` (totals match
   source, time intelligence returns values for the latest period, no blank KPIs), then run the
   `bi-dashboard-design` acceptance checklist. Report what you could not verify.

## Grid mapping (1280 × 720 canvas)

- Margins 16 px; usable width 1248 px; 12 columns of 88 px with 16 px gutters.
- Column span `c` → width `c*88 + (c-1)*16` px; x = `16 + col_index*104`.
- One height unit = 56 px with 16 px gutters (header row ≈ 64 px).
- Long pages: prefer a second page over vertical scrolling for L1/L2; L3 detail pages may
  use a taller canvas (1280 × 1440) for tables.

## Visual mapping

| Spec component | Power BI visual | Notes |
|---|---|---|
| kpi_card | Card (new) / KPI | Reference label for comparison; conditional color via measure |
| trend_line | Line chart | Target as second measure or constant line; 13 months via relative date filter or measure window |
| ranked_bar | Clustered bar | Top N filter + "Other" via a dynamic segmentation measure if needed |
| variance_bar | Clustered bar on variance measure | Color by rule on `Var` sign × direction |
| waterfall | Waterfall | Breakdown field = driver dimension |
| stacked_bar | 100% stacked bar | |
| matrix | Matrix | Rows hierarchy, values Actual/Budget/Var/Var%, cell elements on Var% |
| exception_table | Table | Top N or severity filter, conditional icons, drill-through enabled |
| aging_buckets | Clustered column | Bucket column sorted by bucket order column |
| funnel | Funnel or bar | Bar sorted by stage order is more readable |
| map | Azure Map / filled map | Only if the tenant allows maps |
| slicer | Slicer (dropdown or tile) | Sync slicers across pages for Period and Org |

## Guardrails
- Never hard-code dates like `"2026-10-31"` in measures; derive "latest complete period"
  from the data or a parameter.
- Use `DIVIDE()` for every ratio. Never average a ratio over rows.
- Prefer measures over calculated columns; prefer Power Query / warehouse transforms over
  DAX calculated tables.
- Do not import sensitive columns (SSN, patient name, salary detail) unless the spec asks
  and RLS/OLS is in place.
- Keep Auto date/time off; it bloats the model and conflicts with the Date table.

## Reference files
- `references/tmdl-patterns.md` – TMDL syntax for tables, columns, relationships, Date table,
  roles. Read in mode A/B.
- `references/dax-patterns.md` – reusable DAX: ratios, time intelligence, semi-additive
  snapshots, aging buckets, top N + Other, display helpers, verification queries.
- `references/report-pbir.md` – PBIR folder layout, visual JSON essentials, drill-through,
  bookmarks, and the build-sheet format for mode C.
