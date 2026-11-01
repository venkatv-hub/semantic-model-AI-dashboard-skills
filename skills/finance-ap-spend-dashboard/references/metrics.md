# AP and Spend Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Open AP | Unpaid supplier invoices net of debit memos | Σ open_amount at snapshot | Semi-additive | Context | $ |
| Overdue AP | | Σ open_amount where days_past_due > 0 | Semi-additive | No | $ |
| Due Next 30 Days | Open, not yet due, due within 30 days of snapshot | Σ open_amount where 0 ≤ due_date − snapshot ≤ 30 | Semi-additive | Context | $ |
| DPO | Days payable outstanding | Ending AP ÷ COGS (last 90 days) × 90 | Non-additive | Target band | 0 d |
| On-time Payment % | Paid on or before due date and not early | count(paid_date ≤ due_date AND paid_date ≥ due_date − 5) ÷ count(paid in period) | Ratio | Yes | 0.0% |
| Early Payment % | Paid more than 5 days before due without discount | count(paid_date < due_date − 5 AND discount_taken = 0) ÷ count(paid) | Ratio | No | 0.0% |
| Late Payment % | | count(paid_date > due_date) ÷ count(paid) | Ratio | No | 0.0% |
| Discount Capture % | | Σ discount_taken ÷ Σ discount_amount_available (invoices paid in period) | Ratio | Yes | 0.0% |
| Discounts Missed | | Σ discount_available − Σ discount_taken | Additive | No | $ |
| Invoice Cycle Time | Received → paid, days | median(paid_date − received_date) | Non-additive | No | 0 d |
| Approval Cycle Time | Received → approved | median(approved_date − received_date) | Non-additive | No | 0 d |
| Invoices on Hold | | count / Σ amount where status = On Hold at snapshot | Semi-additive | No | # / $ |
| PO-backed % | | count(po_number not null) ÷ count(invoices received) | Ratio | Yes | 0.0% |
| Touchless % | Auto-matched and approved without manual touch | count(first_pass_match) ÷ count(received) | Ratio | Yes | 0.0% |
| Spend | Invoiced amount (by invoice date) | Σ amount | Additive | Context | $ |

Count-based payment percentages may also be value-weighted; label which one you use.

## Implementations

### On-time Payment %
**DAX** (active relationship on paid date)
```dax
Paid Invoices = CALCULATE ( COUNTROWS ( 'AP Invoices' ), NOT ISBLANK ( 'AP Invoices'[PaidDate] ) )
On-time Payment % =
DIVIDE (
    CALCULATE (
        [Paid Invoices],
        FILTER (
            'AP Invoices',
            'AP Invoices'[PaidDate] <= 'AP Invoices'[DueDate]
                && 'AP Invoices'[PaidDate] >= 'AP Invoices'[DueDate] - 5
        )
    ),
    [Paid Invoices]
)
```
**Tableau**
```
// On-time Payment %
SUM(IF NOT ISNULL([Paid Date]) AND [Paid Date] <= [Due Date] AND [Paid Date] >= DATEADD('day',-5,[Due Date]) THEN 1 ELSE 0 END)
/ SUM(IF NOT ISNULL([Paid Date]) THEN 1 ELSE 0 END)
```
**LookML**
```lookml
dimension: payment_timing {
  type: string
  sql: CASE WHEN ${TABLE}.PAID_DATE IS NULL THEN 'Unpaid'
            WHEN ${TABLE}.PAID_DATE > ${TABLE}.DUE_DATE THEN 'Late'
            WHEN ${TABLE}.PAID_DATE < DATEADD(day, -5, ${TABLE}.DUE_DATE) AND COALESCE(${TABLE}.DISCOUNT_TAKEN,0) = 0 THEN 'Early'
            ELSE 'On time' END ;;
}
measure: paid_invoices { type: count filters: [payment_timing: "-Unpaid"] }
measure: on_time_invoices { type: count filters: [payment_timing: "On time"] }
measure: on_time_payment_pct { type: number sql: 1.0 * ${on_time_invoices} / NULLIF(${paid_invoices}, 0) ;; value_format_name: percent_1 }
```
(`DATEADD(day, …)` is Snowflake syntax; adapt to the dialect.)

### Discount Capture %
**DAX**
```dax
Discount Capture % = DIVIDE ( SUM ( 'AP Invoices'[DiscountTaken] ), SUM ( 'AP Invoices'[DiscountAvailable] ) )
```
**Tableau**
```
SUM([Discount Taken]) / SUM([Discount Available])
```
**LookML**
```lookml
measure: discount_capture_pct {
  type: number
  sql: 1.0 * SUM(${TABLE}.DISCOUNT_TAKEN) / NULLIF(SUM(${TABLE}.DISCOUNT_AVAILABLE), 0) ;;
  value_format_name: percent_1
}
```

### Invoice Cycle Time (median days)
**DAX**
```dax
Invoice Cycle Time (median) =
MEDIANX (
    FILTER ( 'AP Invoices', NOT ISBLANK ( 'AP Invoices'[PaidDate] ) ),
    'AP Invoices'[PaidDate] - 'AP Invoices'[ReceivedDate]
)
```
**Tableau**
```
MEDIAN(DATEDIFF('day', [Received Date], [Paid Date]))
```
**LookML**
```lookml
dimension_group: received_to_paid {
  type: duration
  intervals: [day]
  sql_start: ${TABLE}.RECEIVED_DATE ;;
  sql_end: ${TABLE}.PAID_DATE ;;
}
measure: invoice_cycle_time_median { type: median sql: ${days_received_to_paid} ;; value_format_name: decimal_0 }
```

### DPO
**DAX**
```dax
DPO =
VAR EndDate = MAX ( 'Date'[Date] )
VAR COGS90 = CALCULATE ( [COGS], DATESINPERIOD ( 'Date'[Date], EndDate, -90, DAY ) )
RETURN DIVIDE ( [Open AP], COGS90 ) * 90
```
**Tableau / LookML** – precompute rolling 90-day COGS per day in the warehouse or a derived
table (same approach as standard DSO in `finance-ar-collections-dashboard`).
