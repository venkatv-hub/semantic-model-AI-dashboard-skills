# Dashboard Spec Format

A dashboard spec is the contract between the user and the build. Domain skills fill it in
with their defaults; the user adjusts it; a builder skill implements it. Write it as a
Markdown file named `dashboard-spec.md` (or `<domain>-dashboard-spec.md`) with a YAML block,
followed by short notes for anything the YAML cannot express.

Keep it short enough that a business stakeholder will actually read it — one screen per page.

## Template

```yaml
dashboard:
  id: ar_collections                 # snake_case, used for file and object names
  title: Accounts Receivable & Collections
  domain_skill: finance-ar-collections-dashboard
  platform: powerbi                  # powerbi | tableau | looker
  audience: CFO, Controller, Collections managers
  decisions:                         # the 2-4 decisions this dashboard supports
    - Which customers to escalate this week
    - Whether DSO is trending toward target
  refresh: daily 06:00 local
  currency: USD
  default_period: last_closed_month
  security:
    row_level: business_unit         # dimension used for RLS, or "none"
    sensitive_fields: []             # fields to mask/aggregate

data:
  source: snowflake.finance.ar        # connection / schema / project
  facts:
    - name: AR Open Items
      grain: one row per open invoice per snapshot date
  dimensions: [Date, Customer, Business Unit, Collector]
  assumptions:
    - Credit sales = invoices with payment terms > 0 days

metrics:                              # names must match the domain metrics.md
  - Total AR
  - DSO
  - Overdue %
  - CEI

pages:
  - id: overview
    title: AR Overview
    tier: L1                          # L1 | L2 | L3
    filters: [Period, Business Unit, Currency]
    rows:
      - - {component: kpi_card, metric: Total AR, compare: prior_month, cols: 2}
        - {component: kpi_card, metric: DSO, compare: target, target: 45, cols: 2}
      - - {component: trend_line, metric: DSO, by: Month, periods: 13, reference: target, cols: 8, height: 4}
        - {component: aging_buckets, metric: Total AR, by: Aging Bucket, cols: 4, height: 4}
    drill_through: customer_detail

  - id: customer_detail
    title: Customer Detail
    tier: L3
    drill_from: [overview]
    keys: [Customer]
    rows:
      - - {component: exception_table, columns: [Invoice, Due Date, Days Past Due, Amount, Collector, Status], sort: Days Past Due desc, cols: 12, height: 6}

open_questions:
  - Is "disputed" a status in the source system or a separate table?
```

## Field rules

- `component` must be one of the components in `components.md`.
- `metric` names must exist in the domain skill's `<domain-skill>/references/metrics.md`; add new metrics
  there first (with a definition) rather than inventing them inside the spec.
- `cols` uses the 12-column grid; a row's `cols` should add up to 12. `height` is in grid units
  (1 unit ≈ 56 px in Power BI and Tableau; each builder skill documents its own mapping).
- `compare` is one of `target`, `budget`, `forecast`, `prior_period`, `prior_month`,
  `prior_year`, `none`. L1 cards must not use `none`.
- `by` lists the dimension(s) on the axis; `periods` sets how many time buckets to show.
- `open_questions` collects anything you could not confirm. Never silently guess on
  definitions that change the number (e.g. which invoices count as "credit sales").

## Presenting the spec to the user

Show the YAML plus a three-line summary: who it is for, the headline KPIs, and the pages.
Ask the user to confirm or edit. Then hand the spec to the platform builder skill.
