# LookML Patterns

## Project layout

```
models/finance.model.lkml
explores/ar_open_items.explore.lkml
views/fct_ar_open_items.view.lkml
views/dim_customer.view.lkml
views/dim_date.view.lkml
dashboards/ar_collections.dashboard.lookml
```

## Model

```lookml
connection: "snowflake_finance"

include: "/views/*.view.lkml"
include: "/explores/*.explore.lkml"
include: "/dashboards/*.dashboard.lookml"

datagroup: finance_daily {
  sql_trigger: SELECT MAX(loaded_at) FROM FINANCE.AR.FCT_AR_OPEN_ITEMS ;;
  max_cache_age: "24 hours"
}
persist_with: finance_daily
```

## Fact view

```lookml
view: fct_ar_open_items {
  sql_table_name: FINANCE.AR.FCT_AR_OPEN_ITEMS ;;
  label: "AR Open Items"

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.INVOICE_ID || '|' || TO_CHAR(${TABLE}.SNAPSHOT_DATE, 'YYYY-MM-DD') ;;
  }

  dimension: invoice_id {
    label: "Invoice"
    type: string
    sql: ${TABLE}.INVOICE_ID ;;
    link: {
      label: "Open in ERP"
      url: "https://erp.example.com/invoices/{{ value | url_encode }}"
    }
  }

  dimension: customer_key { hidden: yes type: number sql: ${TABLE}.CUSTOMER_KEY ;; }

  dimension_group: snapshot {
    type: time
    timeframes: [date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.SNAPSHOT_DATE ;;
  }

  dimension: is_period_end {
    hidden: yes
    type: yesno
    sql: ${TABLE}.IS_MONTH_END_SNAPSHOT ;;
  }

  dimension: days_past_due {
    type: number
    sql: ${TABLE}.DAYS_PAST_DUE ;;
  }

  dimension: aging_bucket {
    label: "Aging Bucket"
    type: string
    case: {
      when: { sql: ${days_past_due} <= 0 ;; label: "Current" }
      when: { sql: ${days_past_due} <= 30 ;; label: "1-30" }
      when: { sql: ${days_past_due} <= 60 ;; label: "31-60" }
      when: { sql: ${days_past_due} <= 90 ;; label: "61-90" }
      else: "90+"
    }
  }

  dimension: open_amount { hidden: yes type: number sql: ${TABLE}.OPEN_AMOUNT_USD ;; }

  measure: total_ar {
    label: "Total AR"
    description: "Open receivable balance at period-end snapshots. Do not sum across periods."
    group_label: "01 Balances"
    type: sum
    sql: ${open_amount} ;;
    filters: [is_period_end: "yes"]
    value_format_name: usd_0
    drill_fields: [invoice_id, dim_customer.customer_name, days_past_due, total_ar]
  }

  measure: overdue_ar {
    label: "Overdue AR"
    group_label: "01 Balances"
    type: sum
    sql: ${open_amount} ;;
    filters: [is_period_end: "yes", days_past_due: ">0"]
    value_format_name: usd_0
  }

  measure: overdue_pct {
    label: "Overdue %"
    group_label: "02 Ratios"
    type: number
    sql: 1.0 * ${overdue_ar} / NULLIF(${total_ar}, 0) ;;
    value_format_name: percent_1
  }
}
```

Notes:
- `case:` keeps buckets in declared order for sorting.
- A `tier` dimension (`type: tier`, `tiers: [0, 31, 61, 91]`, `style: integer`) is an
  alternative for numeric bands.
- Prefer an `IS_MONTH_END_SNAPSHOT` flag from the warehouse. If missing, a derived
  dimension with a correlated subquery or a native derived table can compute it; mention the
  performance cost.

## Explore

```lookml
explore: ar_open_items {
  from: fct_ar_open_items
  view_name: fct_ar_open_items
  label: "AR Open Items"
  always_filter: { filters: [fct_ar_open_items.snapshot_date: "last 13 months"] }

  join: dim_customer {
    type: left_outer
    relationship: many_to_one
    sql_on: ${fct_ar_open_items.customer_key} = ${dim_customer.customer_key} ;;
  }

  join: dim_business_unit {
    type: left_outer
    relationship: many_to_one
    sql_on: ${dim_customer.business_unit_key} = ${dim_business_unit.business_unit_key} ;;
  }

  access_filter: {
    field: dim_business_unit.business_unit_name
    user_attribute: business_unit
  }
}
```

Remove `access_filter` when the spec has `row_level: none`.

## Period-over-period

Native period-over-period measures (supported on most modern SQL dialects; check the
connection):

```lookml
measure: revenue_prior_year {
  type: period_over_period
  based_on: revenue
  based_on_time: posting_date_month
  period: year
  kind: previous
  value_format_name: usd_0
}

measure: revenue_yoy_pct {
  type: period_over_period
  based_on: revenue
  based_on_time: posting_date_month
  period: year
  kind: relative_change
  value_format_name: percent_1
}
```

Fallback with filtered measures driven by a reporting-period parameter or relative filters:

```lookml
measure: revenue_last_month {
  type: sum
  sql: ${amount} ;;
  filters: [posting_date: "last month"]
  value_format_name: usd_0
}

measure: revenue_same_month_ly {
  type: sum
  sql: ${amount} ;;
  filters: [posting_date: "13 months ago for 1 month"]
  value_format_name: usd_0
}
```

## Ratios and targets

```lookml
measure: gross_margin_pct {
  type: number
  sql: 1.0 * ${gross_margin} / NULLIF(${revenue}, 0) ;;
  value_format_name: percent_1
}

measure: dso_target {
  hidden: yes
  type: number
  sql: 45 ;;   # or join a targets table on metric + month
}
```

## Display helpers

```lookml
measure: dso_status {
  type: string
  sql: CASE WHEN ${dso} <= ${dso_target} THEN 'On track'
            WHEN ${dso} <= ${dso_target} * 1.1 THEN 'Watch'
            ELSE 'Off track' END ;;
  html: {% if value == 'On track' %}<span style="color:#1A7F37">●</span>
        {% elsif value == 'Watch' %}<span style="color:#B7791F">●</span>
        {% else %}<span style="color:#C62828">●</span>{% endif %} {{ value }} ;;
}
```

## Tests

```lookml
test: total_ar_matches_reference {
  explore_source: ar_open_items {
    column: total_ar { field: fct_ar_open_items.total_ar }
    filters: [fct_ar_open_items.snapshot_month: "2026-09"]
  }
  assert: ar_is_positive {
    expression: ${fct_ar_open_items.total_ar} > 0 ;;
  }
}
```

Replace the assertion with an equality check against a reconciled number when the user
provides one.
