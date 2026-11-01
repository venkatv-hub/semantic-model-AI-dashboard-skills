# Procurement Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Total Spend | Invoiced external spend (excl. tax, intercompany) | Σ amount | Additive | Context | $ |
| PO Coverage % | Spend with a PO reference | Σ amount where po_number not null ÷ Σ addressable amount | Ratio | Yes | 0.0% |
| On-contract Spend % | Spend linked to an active contract at invoice date | Σ amount where contract active ÷ Σ addressable amount | Ratio | Yes | 0.0% |
| Spend Under Management % | Spend influenced by procurement (on contract OR catalog OR sourced) | Σ managed amount ÷ Σ addressable amount | Ratio | Yes | 0.0% |
| Addressable Spend | Spend in categories procurement can influence | Σ amount where category.addressable = true | Additive | – | $ |
| Maverick Spend | Addressable spend without PO or off-contract where a preferred supplier exists | Σ amount where maverick_flag | Additive | No | $ |
| PPV | Purchase price variance vs baseline | Σ (actual_unit_price − baseline_unit_price) × qty | Additive | No (negative is favorable) | +$ |
| PPV % | | PPV ÷ Σ (baseline_unit_price × qty) | Ratio | No | +0.0% |
| Supplier OTD % | PO lines fully received on/before confirmed date | count(on_time_lines) ÷ count(lines due in period) | Ratio | Yes | 0.0% |
| Defect PPM | | Σ rejected_qty ÷ Σ received_qty × 1,000,000 | Ratio | No | #,0 |
| Average Lead Time | PO order date to receipt | avg(receipt_date − order_date) by line | Non-additive | No | 0.0 d |
| Lead Time Variability | Std. deviation of lead time | stdev(receipt_date − order_date) | Non-additive | No | 0.0 d |
| Top-1 Supplier Share | Largest supplier's share of category spend | max over suppliers(Σ spend) ÷ Σ category spend | Non-additive | No | 0% |
| Pareto Cumulative % | Running share of spend by supplier rank | running Σ spend (desc) ÷ total | Table calc | – | 0% |

## Implementations

### PPV
**DAX**
```dax
PPV = SUMX ( 'PO Receipts', ( 'PO Receipts'[ActualUnitPrice] - 'PO Receipts'[BaselineUnitPrice] ) * 'PO Receipts'[ReceivedQty] )
PPV % = DIVIDE ( [PPV], SUMX ( 'PO Receipts', 'PO Receipts'[BaselineUnitPrice] * 'PO Receipts'[ReceivedQty] ) )
```
**Tableau**
```
// PPV
SUM(([Actual Unit Price] - [Baseline Unit Price]) * [Received Qty])
// PPV %
[PPV] / SUM([Baseline Unit Price] * [Received Qty])
```
**LookML**
```lookml
measure: ppv { type: sum sql: (${actual_unit_price} - ${baseline_unit_price}) * ${received_qty} ;; value_format_name: usd_0 }
measure: baseline_value { hidden: yes type: sum sql: ${baseline_unit_price} * ${received_qty} ;; }
measure: ppv_pct { type: number sql: 1.0 * ${ppv} / NULLIF(${baseline_value}, 0) ;; value_format_name: percent_1 }
```

### PO Coverage %
**DAX**
```dax
PO Coverage % =
DIVIDE (
    CALCULATE ( [Spend], NOT ISBLANK ( Spend[PONumber] ), Category[Addressable] = TRUE () ),
    CALCULATE ( [Spend], Category[Addressable] = TRUE () )
)
```
**Tableau**
```
SUM(IF [Addressable] AND NOT ISNULL([PO Number]) THEN [Amount] END) / SUM(IF [Addressable] THEN [Amount] END)
```
**LookML**
```lookml
measure: addressable_spend { type: sum sql: ${amount} ;; filters: [dim_category.addressable: "yes"] }
measure: po_spend { type: sum sql: ${amount} ;; filters: [dim_category.addressable: "yes", po_number: "-NULL"] }
measure: po_coverage_pct { type: number sql: 1.0 * ${po_spend} / NULLIF(${addressable_spend}, 0) ;; value_format_name: percent_1 }
```

### Defect PPM
**DAX**
```dax
Defect PPM = DIVIDE ( SUM ( Receipts[RejectedQty] ), SUM ( Receipts[ReceivedQty] ) ) * 1000000
```
**Tableau**
```
SUM([Rejected Qty]) / SUM([Received Qty]) * 1000000
```
**LookML**
```lookml
measure: defect_ppm { type: number sql: 1000000.0 * SUM(${TABLE}.REJECTED_QTY) / NULLIF(SUM(${TABLE}.RECEIVED_QTY), 0) ;; value_format_name: decimal_0 }
```

### Pareto cumulative %
**DAX**
```dax
Supplier Spend Rank = RANKX ( ALLSELECTED ( Supplier[Parent Supplier] ), [Spend], , DESC, DENSE )
Pareto Cumulative % =
VAR r = [Supplier Spend Rank]
VAR Running =
    SUMX ( FILTER ( ALLSELECTED ( Supplier[Parent Supplier] ), [Supplier Spend Rank] <= r ), [Spend] )
RETURN DIVIDE ( Running, CALCULATE ( [Spend], ALLSELECTED ( Supplier[Parent Supplier] ) ) )
```
**Tableau** – `RUNNING_SUM(SUM([Amount])) / TOTAL(SUM([Amount]))`, compute using Parent
Supplier, sorted by spend descending.
**LookML** – derived table:
```sql
SELECT parent_supplier, spend,
       SUM(spend) OVER (ORDER BY spend DESC ROWS UNBOUNDED PRECEDING) / SUM(spend) OVER () AS cumulative_pct
FROM (SELECT parent_supplier, SUM(amount) AS spend FROM fact_spend GROUP BY 1)
```
Note: the derived table ignores dashboard filters unless you templatize them with
`{% condition %}` blocks.
