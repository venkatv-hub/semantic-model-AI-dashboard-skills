---
name: looker-dashboard-builder
description: Builds Looker semantic models and dashboards from a dashboard spec — LookML views, explores and models, measures with period-over-period and snapshot logic, drill fields, access filters, and LookML dashboards (.dashboard.lookml) on the newspaper layout. Use this skill whenever the user wants a Looker dashboard, LookML model, explore, view, measure or Looker semantic layer created or changed, including when a domain skill (finance, supply chain, healthcare, sales, HR) has produced a dashboard spec and the target platform is Looker or Looker (Google Cloud core).
---

# Looker Dashboard Builder

Turns a dashboard spec (see `bi-dashboard-design/references/dashboard-spec.md`) into LookML.
Looker is the most automatable of the three platforms: the semantic model **and** the
dashboard are plain text files in a Git-backed LookML project.

## Choose the build mode first

| Mode | When | What you produce |
|---|---|---|
| **A. Live project** | Looker MCP/Toolbox tools or Looker API access are available | LookML written into the project branch, validated with the LookML validator, test queries run, dashboard imported |
| **B. Files** | You can write files (local clone of the LookML repo) | `views/*.view.lkml`, `explores/*.explore.lkml`, `models/*.model.lkml`, `dashboards/*.dashboard.lookml` |
| **C. Build kit** | Chat only | Same LookML as code blocks plus deployment steps |

Always work in a development branch; never push directly to production.

## Workflow

1. **Read the spec and the domain metrics file.** Each measure must match a domain
   definition; put the definition in the measure's `description`.
2. **Views** (`references/lookml-patterns.md`): one view per table, `sql_table_name` from the
   spec's source, a unique `primary_key` (compound keys concatenated), `dimension_group` of
   `type: time` for every date, business labels, `group_label` folders, `hidden: yes` on keys,
   `value_format_name` on every measure.
3. **Explores:** one explore per fact (base view = fact), `many_to_one` joins to dimensions,
   `relationship` declared on every join. Avoid fanout: never join a second fact at a finer
   grain into the same explore without symmetric aggregates and a tested primary key. Add
   `always_filter` on the date for large facts.
4. **Measures:** base measures first, ratios as `type: number` over other measures, snapshot
   measures filtered to period-end rows, period comparisons with `period_over_period` or
   filtered measures, display helpers via `html:` only when needed.
5. **Dashboard** (`references/dashboard-lookml.md`): a LookML dashboard with `layout:
   newspaper`, dashboard filters wired to every element with `listen`, elements placed using
   the grid mapping. Optionally import it as a user-defined dashboard so business users can
   edit it.
6. **Security:** add `access_filter` on the secured dimension using a user attribute when the
   spec has `row_level`; use `required_access_grants` for sensitive fields.
7. **Verify:** run the LookML validator, run test queries for each L1 measure against the
   latest period, compare totals with SQL Runner, then run the `bi-dashboard-design`
   acceptance checklist. Add LookML `test:` blocks for key totals when the user has stable
   reference numbers.

## Grid mapping (newspaper layout)

- Newspaper layout is 24 columns wide: `width = cols * 2`, `col = start_col * 2`.
- Height units: KPI tiles `height: 3`, charts `height: 6–8`, tables `height: 8–10`.
- Rows are placed by `row:`; increment by the height of the tallest element in the row above.

## Visual mapping

| Spec component | Looker element `type` | Notes |
|---|---|---|
| kpi_card | `single_value` | Second field as comparison; `comparison_reverse_colors: true` when lower is better |
| trend_line | `looker_line` | Target/PY as second series, dashed via `series_types`/style |
| ranked_bar | `looker_bar` | `sorts: [measure desc]`, `limit: 10`, row totals off |
| variance_bar | `looker_bar` on variance measure | Color via `series_colors` or conditional formatting |
| waterfall | `looker_waterfall` if enabled, otherwise a variance bar | |
| stacked_bar | `looker_bar` with `stacking: percent` or `normal` | |
| matrix | `looker_grid` with pivots and subtotals | Conditional formatting on one measure |
| exception_table | `looker_grid` | `sorts` by severity, `link` to source system |
| aging_buckets | `looker_column` on a `tier` or `case` dimension | Use `case` with ordered `when`s so sort is fixed |
| funnel | `looker_funnel` or ordered bar | |
| map | `looker_map` / `looker_geo_choropleth` | Needs `map_layer_name` on the dimension |
| slicer | dashboard `filters:` with `ui_config` | |

## Guardrails
- Never use `type: sum` on a balance column without a period-end or latest-snapshot filter.
- Ratios use `NULLIF(..., 0)` in SQL.
- Keep business logic in the model, not in dashboard `dynamic_fields` (table calculations),
  unless it is purely presentational.
- Don't expose raw PII/PHI dimensions; hide them or protect with access grants.

## Reference files
- `references/lookml-patterns.md` – views, explores, measures, period-over-period, snapshots,
  buckets, access filters, tests.
- `references/dashboard-lookml.md` – LookML dashboard structure, filters, element examples.
