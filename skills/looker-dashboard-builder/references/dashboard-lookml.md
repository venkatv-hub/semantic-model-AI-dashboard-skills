# LookML Dashboards

LookML dashboards (`.dashboard.lookml`) are YAML. They are version-controlled with the model
and can be imported as user-defined dashboards (UDDs) for business users to edit.

## Skeleton

```yaml
- dashboard: ar_collections
  title: "Accounts Receivable & Collections"
  description: "L1 overview of receivables, DSO and collection effectiveness."
  layout: newspaper
  preferred_viewer: dashboards-next
  crossfilter_enabled: true
  refresh: 1 day

  filters:
  - name: Period
    title: "Period"
    type: field_filter
    default_value: "last month"
    allow_multiple_values: false
    required: true
    ui_config:
      type: relative_timeframes
      display: inline
    model: finance
    explore: ar_open_items
    field: fct_ar_open_items.snapshot_month

  - name: Business Unit
    title: "Business Unit"
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: tag_list
      display: popover
    model: finance
    explore: ar_open_items
    field: dim_business_unit.business_unit_name

  elements:
  - name: header
    type: text
    title_text: "Accounts Receivable & Collections"
    subtitle_text: "Period-end balances · USD · refreshed daily"
    row: 0
    col: 0
    width: 24
    height: 2

  - name: kpi_total_ar
    title: "Total AR"
    model: finance
    explore: ar_open_items
    type: single_value
    fields: [fct_ar_open_items.total_ar]
    listen:
      Period: fct_ar_open_items.snapshot_month
      Business Unit: dim_business_unit.business_unit_name
    note_text: "Open receivable balance at period end."
    row: 2
    col: 0
    width: 4
    height: 3

  - name: kpi_dso
    title: "DSO (days)"
    model: finance
    explore: ar_open_items
    type: single_value
    fields: [fct_ar_open_items.dso, fct_ar_open_items.dso_target]
    show_comparison: true
    comparison_type: progress_percentage
    comparison_reverse_colors: true
    show_comparison_label: true
    comparison_label: "of target"
    listen:
      Period: fct_ar_open_items.snapshot_month
      Business Unit: dim_business_unit.business_unit_name
    row: 2
    col: 4
    width: 4
    height: 3

  - name: dso_trend
    title: "DSO trend vs target (13 months)"
    model: finance
    explore: ar_open_items
    type: looker_line
    fields: [fct_ar_open_items.snapshot_month, fct_ar_open_items.dso, fct_ar_open_items.dso_target]
    sorts: [fct_ar_open_items.snapshot_month]
    filters:
      fct_ar_open_items.snapshot_month: "13 months"
    listen:
      Business Unit: dim_business_unit.business_unit_name
    series_colors:
      fct_ar_open_items.dso: "#2563EB"
      fct_ar_open_items.dso_target: "#A1A1AA"
    row: 5
    col: 0
    width: 16
    height: 7

  - name: aging
    title: "AR by aging bucket"
    model: finance
    explore: ar_open_items
    type: looker_column
    fields: [fct_ar_open_items.aging_bucket, fct_ar_open_items.total_ar]
    sorts: [fct_ar_open_items.aging_bucket]
    listen:
      Period: fct_ar_open_items.snapshot_month
      Business Unit: dim_business_unit.business_unit_name
    row: 5
    col: 16
    width: 8
    height: 7

  - name: top_overdue
    title: "Top 15 overdue customers"
    model: finance
    explore: ar_open_items
    type: looker_grid
    fields: [dim_customer.customer_name, fct_ar_open_items.overdue_ar, fct_ar_open_items.overdue_pct]
    sorts: [fct_ar_open_items.overdue_ar desc]
    limit: 15
    listen:
      Period: fct_ar_open_items.snapshot_month
      Business Unit: dim_business_unit.business_unit_name
    row: 12
    col: 0
    width: 24
    height: 8
```

## Rules
- Every element listens to every global filter that applies to its explore. Elements that
  must ignore the period (13-month trends) set their own `filters:` and omit `Period` from
  `listen`.
- Element `name` values are unique and stable; they become the anchor for UDD imports.
- Keep `title` question- or insight-style per `bi-dashboard-design`.
- Comparison options for `single_value`: `comparison_type` is `value`, `change` or
  `progress`/`progress_percentage`; the second field in `fields` is the comparison.
- L3 drill-through: use measure `drill_fields` and a `link` to a detail dashboard with
  filters passed in the URL (`/dashboards/finance::ar_customer_detail?Customer={{ value }}`).
- After writing, run the LookML validator; dashboard YAML errors surface there.
