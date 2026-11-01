# Order Fulfillment Metric Definitions

Grain: order line (`fact_order_line_fulfillment`), measured in the period of the reference
date (requested date by default). "Measurable line" = not cancelled AND (delivered OR
reference date < today).

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| On-time flag | Delivered on/before reference date (+ tolerance) | delivered_date ≤ reference_date + tol_late AND delivered_date ≥ reference_date − tol_early | Row-level | – | yes/no |
| In-full flag | Delivered qty by reference date ≥ ordered qty × in-full threshold | qty_delivered_by_ref_date ≥ ordered_qty × 1.00 | Row-level | – | yes/no |
| OTIF % | Lines both on time and in full | count(on_time AND in_full) ÷ count(measurable lines) | Ratio | Yes | 0.0% |
| On-time % | | count(on_time) ÷ count(measurable lines) | Ratio | Yes | 0.0% |
| In-full % | | count(in_full) ÷ count(measurable lines) | Ratio | Yes | 0.0% |
| Fill Rate (units) | Units delivered vs ordered | Σ min(delivered_qty, ordered_qty) ÷ Σ ordered_qty | Ratio | Yes | 0.0% |
| Order Cycle Time | Order creation to final delivery | median(delivered_date − order_date) | Non-additive | No | 0.0 d |
| Average Days Late | For late lines only | avg(delivered_date − reference_date) where late | Non-additive | No | 0.0 d |
| Backorder Value | Open ordered value past its reference date without stock | Σ open_value where status = backorder (snapshot) | Semi-additive | No | $ |
| Perfect Order % | OTIF AND no damage AND correct documentation/invoice | count(perfect) ÷ count(measurable orders) | Ratio | Yes | 0.0% |
| Carrier On-time % | Carrier delivered by carrier-committed date | count(delivered ≤ carrier_due) ÷ count(shipments delivered) | Ratio | Yes | 0.0% |
| Freight Cost per Unit | | Σ freight_cost ÷ Σ shipped_qty (same UOM) | Ratio | No | $0.00 |
| Freight % of Revenue | | Σ freight_cost ÷ Σ shipped order value | Ratio | No | 0.0% |

Undelivered lines whose reference date has passed: on_time = false; in_full = false unless
the full quantity was delivered (late).

## Implementations

### OTIF % (line level)
**DAX** (`OnTimeFlag`, `InFullFlag`, `IsMeasurable` as 0/1 columns from the warehouse)
```dax
Measurable Lines = SUM ( 'Order Line Fulfillment'[IsMeasurable] )
OTIF Lines =
SUMX ( 'Order Line Fulfillment',
    'Order Line Fulfillment'[IsMeasurable] * 'Order Line Fulfillment'[OnTimeFlag] * 'Order Line Fulfillment'[InFullFlag] )
OTIF % = DIVIDE ( [OTIF Lines], [Measurable Lines] )
On-time % = DIVIDE ( SUMX ( 'Order Line Fulfillment', 'Order Line Fulfillment'[IsMeasurable] * 'Order Line Fulfillment'[OnTimeFlag] ), [Measurable Lines] )
```
**Tableau**
```
// OTIF %
SUM(IF [Is Measurable] AND [On Time Flag] AND [In Full Flag] THEN 1 ELSE 0 END)
/ SUM(IF [Is Measurable] THEN 1 ELSE 0 END)
```
**LookML**
```lookml
dimension: is_measurable { type: yesno sql: ${TABLE}.IS_MEASURABLE ;; }
dimension: on_time { type: yesno sql: ${TABLE}.ON_TIME_FLAG ;; }
dimension: in_full { type: yesno sql: ${TABLE}.IN_FULL_FLAG ;; }
measure: measurable_lines { type: count filters: [is_measurable: "yes"] }
measure: otif_lines { type: count filters: [is_measurable: "yes", on_time: "yes", in_full: "yes"] }
measure: otif_pct { type: number sql: 1.0 * ${otif_lines} / NULLIF(${measurable_lines}, 0) ;; value_format_name: percent_1 }
```

### Warehouse logic for the flags (reference SQL, Snowflake dialect)
```sql
SELECT
  l.order_id, l.line_id, l.requested_date AS reference_date, l.ordered_qty,
  MAX(s.delivered_date) AS last_delivered_date,
  SUM(CASE WHEN s.delivered_date <= l.requested_date THEN s.shipped_qty ELSE 0 END) AS qty_by_ref_date,
  SUM(s.shipped_qty) AS delivered_qty,
  IFF(l.status <> 'CANCELLED' AND (MAX(s.delivered_date) IS NOT NULL OR l.requested_date < CURRENT_DATE), 1, 0) AS is_measurable,
  IFF(MAX(s.delivered_date) <= l.requested_date AND SUM(s.shipped_qty) >= l.ordered_qty, 1, 0) AS on_time_flag,
  IFF(SUM(CASE WHEN s.delivered_date <= l.requested_date THEN s.shipped_qty ELSE 0 END) >= l.ordered_qty, 1, 0) AS in_full_flag
FROM fact_order_lines l
LEFT JOIN fact_shipments s ON s.order_id = l.order_id AND s.line_id = l.line_id AND s.is_delivered
GROUP BY 1,2,3,4, l.status;
```
This measures on-time on the last delivery needed to complete the line; adjust if the
business measures first delivery.

### Fill Rate
**DAX**
```dax
Fill Rate =
DIVIDE (
    SUMX ( 'Order Line Fulfillment', MIN ( 'Order Line Fulfillment'[DeliveredQty], 'Order Line Fulfillment'[OrderedQty] ) ),
    SUM ( 'Order Line Fulfillment'[OrderedQty] )
)
```
**Tableau**
```
SUM(MIN([Delivered Qty], [Ordered Qty])) / SUM([Ordered Qty])
```
**LookML**
```lookml
measure: fill_rate {
  type: number
  sql: 1.0 * SUM(LEAST(${TABLE}.DELIVERED_QTY, ${TABLE}.ORDERED_QTY)) / NULLIF(SUM(${TABLE}.ORDERED_QTY), 0) ;;
  value_format_name: percent_1
}
```
