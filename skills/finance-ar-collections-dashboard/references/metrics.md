# AR and Collections Metric Definitions

"Snapshot" = the period-end snapshot in the filter context (month-end by default).
Amounts in reporting currency.

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Total AR | Net open receivable balance | Σ open_amount at snapshot | Semi-additive (not over time) | Context | $ |
| Gross AR | Open invoices only (excl. credits/unapplied cash) | Σ open_amount where open_amount > 0 | Semi-additive | Context | $ |
| Current AR | Open amount not yet due | Σ open_amount where days_past_due ≤ 0 | Semi-additive | – | $ |
| Overdue AR | Open amount past due | Σ open_amount where days_past_due > 0 | Semi-additive | No | $ |
| Overdue % | | Overdue AR ÷ Gross AR | Ratio | No | 0.0% |
| AR 90+ % | Share of gross AR more than 90 days past due | AR(dpd > 90) ÷ Gross AR | Ratio | No | 0.0% |
| Disputed AR | Open amount flagged in dispute | Σ open_amount where dispute_flag | Semi-additive | No | $ |
| Credit Sales | Invoiced sales on credit terms in the period | Σ invoice amount where payment_terms_days > 0 | Additive | – | $ |
| Cash Collected | Customer payments received in period | Σ payment amount | Additive | Yes | $ |
| DSO (count-back) | Days of most recent credit sales that make up ending AR | see below | Non-additive | No | 0 d |
| DSO (standard) | | Ending AR ÷ credit sales of last N days × N (N = 90 default) | Non-additive | No | 0 d |
| CEI | Collection Effectiveness Index | (Begin AR + Credit Sales − End Total AR) ÷ (Begin AR + Credit Sales − End Current AR) × 100 | Non-additive | Yes (≥ 80 good) | 0.0 |
| Average Days to Pay | Payment-weighted days from invoice to payment | Σ(amount × (payment_date − invoice_date)) ÷ Σ amount for invoices paid in period | Ratio | No | 0 d |
| Average Days Late | | Σ(amount × max(0, payment_date − due_date)) ÷ Σ amount | Ratio | No | 0 d |
| Credit Limit Utilization | | Customer AR ÷ credit_limit | Ratio | No | 0% |
| Severity Score (worklist sort) | Prioritizes invoices to chase | open_amount × (1 + days_past_due / 30) | Row-level | – | number |

**Count-back DSO algorithm.** Start with ending AR. Walk back month by month from the
snapshot month, subtracting each month's credit sales while the remaining AR is ≥ that
month's sales, adding that month's days. In the first month where the remaining AR is smaller
than the month's sales, add `remaining ÷ month sales × days in month` and stop.

## Edge cases
- Customers with only credit balances: exclude from Overdue % denominator (use Gross AR).
- CEI denominator ≤ 0 (tiny AR) → blank.
- Invoices with no due date: use invoice_date + payment_terms_days.
- A month with zero credit sales in count-back: add its days and continue.

## Implementations

### Total AR (period-end snapshot)
**DAX**
```dax
Total AR =
CALCULATE (
    SUM ( 'AR Open Items'[OpenAmount] ),
    LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'AR Open Items' ) ) )
)
```
**Tableau**
```
// Total AR (period-end)
SUM(IF [Is Period-End Snapshot] THEN [Open Amount] END)
```
**LookML**
```lookml
measure: total_ar { type: sum sql: ${open_amount} ;; filters: [is_period_end: "yes"] value_format_name: usd_0 }
```

### Overdue %
**DAX**
```dax
Overdue AR = CALCULATE ( [Total AR], 'AR Open Items'[DaysPastDue] > 0 )
Gross AR = CALCULATE ( [Total AR], 'AR Open Items'[OpenAmount] > 0 )
Overdue % = DIVIDE ( [Overdue AR], [Gross AR] )
```
**Tableau**
```
// Overdue %
SUM(IF [Is Period-End Snapshot] AND [Days Past Due] > 0 THEN [Open Amount] END)
/ SUM(IF [Is Period-End Snapshot] AND [Open Amount] > 0 THEN [Open Amount] END)
```
**LookML**
```lookml
measure: gross_ar { type: sum sql: ${open_amount} ;; filters: [is_period_end: "yes", open_amount: ">0"] }
measure: overdue_pct { type: number sql: 1.0 * ${overdue_ar} / NULLIF(${gross_ar}, 0) ;; value_format_name: percent_1 }
```

### DSO (count-back)
**DAX**
```dax
DSO Countback =
VAR EndDate = MAX ( 'Date'[Date] )
VAR AR = [Total AR]
VAR Months =
    CALCULATETABLE (
        ADDCOLUMNS (
            VALUES ( 'Date'[Month Start] ),
            "@Sales", CALCULATE ( [Credit Sales] ),
            "@Days", DAY ( EOMONTH ( 'Date'[Month Start], 0 ) )
        ),
        REMOVEFILTERS ( 'Date' ),
        DATESINPERIOD ( 'Date'[Date], EndDate, -12, MONTH )
    )
VAR WithCum =
    ADDCOLUMNS (
        Months,
        "@Cum",
            VAR m = 'Date'[Month Start]
            RETURN SUMX ( FILTER ( Months, 'Date'[Month Start] >= m ), [@Sales] )
    )
VAR FullDays = SUMX ( FILTER ( WithCum, [@Cum] <= AR ), [@Days] )
VAR Partial = TOPN ( 1, FILTER ( WithCum, [@Cum] > AR ), 'Date'[Month Start], DESC )
VAR PartialDays = SUMX ( Partial, DIVIDE ( AR - ( [@Cum] - [@Sales] ), [@Sales] ) * [@Days] )
RETURN IF ( ISBLANK ( AR ), BLANK (), FullDays + PartialDays )
```
**Tableau** – precompute in the warehouse (recommended) as `dso_countback` at
customer-group × month, or compute standard DSO with a table calc on a monthly view:
```
// DSO standard (3 months), compute using Month of Snapshot Date
SUM([Total AR]) / WINDOW_SUM(SUM([Credit Sales]), -2, 0) * WINDOW_SUM(MIN([Days In Month]), -2, 0)
```
**LookML** – derived table with monthly AR and credit sales, then compute in SQL:
```lookml
view: dso_monthly {
  derived_table: {
    sql:
      SELECT month,
             ar,
             ar / NULLIF(SUM(credit_sales) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0)
               * SUM(days_in_month) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS dso_standard
      FROM ${ar_monthly_summary.SQL_TABLE_NAME} ;;
  }
  dimension_group: month { type: time timeframes: [month] datatype: date sql: ${TABLE}.month ;; }
  measure: dso_standard { type: average sql: ${TABLE}.dso_standard ;; value_format_name: decimal_0 }
}
```
(`type: average` is safe only when one row per month is in context; keep this explore at
month grain.) For count-back, materialize it in the warehouse.

### CEI
**DAX**
```dax
CEI =
VAR BeginAR = CALCULATE ( [Total AR], DATEADD ( 'Date'[Date], -1, MONTH ) )
VAR Sales = [Credit Sales]
VAR EndAR = [Total AR]
VAR EndCurrent = CALCULATE ( [Total AR], 'AR Open Items'[DaysPastDue] <= 0 )
RETURN DIVIDE ( BeginAR + Sales - EndAR, BeginAR + Sales - EndCurrent ) * 100
```
**Tableau** (monthly view, compute using month)
```
(LOOKUP([Total AR], -1) + SUM([Credit Sales]) - [Total AR])
/ (LOOKUP([Total AR], -1) + SUM([Credit Sales]) - [Current AR]) * 100
```
**LookML** – compute in the `ar_monthly_summary` derived table with `LAG(ar)` and expose as
a measure at month grain.
