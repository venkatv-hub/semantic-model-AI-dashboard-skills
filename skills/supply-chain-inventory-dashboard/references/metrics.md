# Inventory Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Inventory Value | On-hand value at cost at snapshot | Σ on_hand_value at snapshot | Semi-additive | Context | $ |
| Inventory Units | On-hand quantity (base UOM only) | Σ on_hand_qty | Semi-additive, same UOM | Context | # |
| Average Inventory Value | Mean of period-end values over the period | AVG over months of month-end Inventory Value | Non-additive | – | $ |
| COGS (inventory) | Cost of goods issued to sales/production | Σ value of issue movements | Additive | – | $ |
| Inventory Turns | Annualized | (COGS in period × 365 ÷ days in period) ÷ Average Inventory Value | Non-additive | Yes | 0.0x |
| Avg Daily Demand | Forecast daily demand next N days (default 28) or trailing 90-day consumption ÷ 90 | Σ forecast_qty(next N) ÷ N | Non-additive | – | # |
| Days of Supply | Days current stock covers demand | Σ on_hand_qty ÷ Σ avg daily demand (value-based at aggregate: Σ value ÷ Σ daily COGS) | Non-additive | Target band | 0 d |
| Stockout Rate | Share of active SKU-locations with zero available stock and demand > 0 | count(available ≤ 0 AND demand > 0) ÷ count(active SKU-locations with demand) | Ratio | No | 0.0% |
| Below Safety Stock % | | count(available < safety_stock) ÷ count(active with safety stock) | Ratio | No | 0.0% |
| Excess Value | Value above 180 days of supply | Σ max(0, on_hand_qty − 180 × daily demand) × unit_cost | Semi-additive | No | $ |
| Obsolete Value | No movement ≥ 365 days or lifecycle = EOL | Σ on_hand_value where days_since_last_movement ≥ 365 OR EOL | Semi-additive | No | $ |
| E&O % | | (Excess + Obsolete) ÷ Inventory Value | Ratio | No | 0.0% |
| Inventory Age Bucket | Age by receipt layer or days since last receipt | 0–30, 31–90, 91–180, 181–365, 365+ | Dimension | – | – |
| Cycle Count Accuracy % | Counts within tolerance | count(|counted − system| ≤ tolerance) ÷ count(counts) | Ratio | Yes | 0.0% |

Available stock = on_hand_qty − allocated_qty (optionally + in-transit due within lead time).

## Edge cases
- Zero demand → DOS shows "No demand" (blank + label), excluded from averages.
- Avoid double counting obsolete stock in excess: compute excess on non-obsolete items only.
- Inventory value at standard cost changes when standards are revalued; note the revaluation
  date on trends.

## Implementations

### Inventory Value (period-end)
**DAX**
```dax
Inventory Value =
CALCULATE (
    SUM ( 'Inventory Snapshot'[OnHandValue] ),
    LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'Inventory Snapshot' ) ) )
)
```
**Tableau**
```
SUM(IF [Is Period-End Snapshot] THEN [On Hand Value] END)
```
**LookML**
```lookml
measure: inventory_value { type: sum sql: ${on_hand_value} ;; filters: [is_period_end: "yes"] value_format_name: usd_0 }
```

### Inventory Turns (annualized)
**DAX**
```dax
Average Inventory Value =
AVERAGEX ( VALUES ( 'Date'[Month Start] ), CALCULATE ( [Inventory Value] ) )

Inventory Turns =
VAR Days = COUNTROWS ( 'Date' )
RETURN DIVIDE ( [COGS] * 365 / Days, [Average Inventory Value] )
```
**Tableau** (view or KPI filtered to a date range; month-end flag on the snapshot)
```
// Average inventory value: average of month-end totals
WINDOW_AVG(SUM(IF [Is Period-End Snapshot] THEN [On Hand Value] END))   // compute using Month

// Turns (precompute COGS annualization factor as a parameter or FIXED day count)
(SUM([COGS]) * 365 / {FIXED : COUNTD([Movement Date])}) / [Average Inventory Value]
```
Prefer a warehouse monthly summary (month, avg_inventory, cogs) for Tableau KPIs to avoid
mixing table calcs and LODs.
**LookML** – monthly summary derived table:
```lookml
view: inventory_monthly {
  derived_table: {
    sql: SELECT DATE_TRUNC('month', snapshot_date) AS month, item_key, location_key,
                SUM(CASE WHEN is_month_end_snapshot THEN on_hand_value END) AS month_end_value
         FROM ANALYTICS.SC.FCT_INVENTORY_SNAPSHOT GROUP BY 1,2,3 ;;
  }
  measure: avg_inventory_value {
    type: number
    sql: SUM(${TABLE}.month_end_value) / NULLIF(COUNT(DISTINCT ${TABLE}.month), 0) ;;
    value_format_name: usd_0
  }
}
```
Turns = `cogs_annualized / avg_inventory_value` as a `type: number` measure in an explore
that joins COGS at the same month grain.

### Days of Supply
**DAX**
```dax
Days of Supply =
VAR Qty = CALCULATE ( SUM ( 'Inventory Snapshot'[OnHandQty] ), LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'Inventory Snapshot' ) ) ) )
VAR Daily = DIVIDE ( [Forecast Qty Next 28D], 28 )
RETURN IF ( Daily > 0, MIN ( DIVIDE ( Qty, Daily ), 999 ) )
```
**Tableau**
```
// Days of Supply
IF SUM([Avg Daily Demand]) > 0 THEN MIN(SUM(IF [Is Period-End Snapshot] THEN [On Hand Qty] END) / SUM([Avg Daily Demand]), 999) END
```
**LookML**
```lookml
measure: days_of_supply {
  type: number
  sql: LEAST(${on_hand_qty_period_end} / NULLIF(${avg_daily_demand}, 0), 999) ;;
  value_format_name: decimal_0
}
```

### Stockout Rate
**DAX**
```dax
Stockout Rate =
VAR SKULocs =
    FILTER (
        SUMMARIZE ( 'Inventory Snapshot', 'Inventory Snapshot'[ItemKey], 'Inventory Snapshot'[LocationKey] ),
        [Forecast Qty Next 28D] > 0
    )
RETURN
DIVIDE (
    COUNTROWS ( FILTER ( SKULocs, [Available Qty] <= 0 ) ),
    COUNTROWS ( SKULocs )
)
```
**Tableau**
```
// row-level flag at SKU-location grain (use FIXED to collapse snapshots)
{FIXED [SKU], [Location] : SUM(IF [Is Latest Snapshot] THEN [Available Qty] END)} <= 0
```
then `SUM(INT([Stockout Flag] AND [Has Demand])) / SUM(INT([Has Demand]))` at a
SKU-location-level data source or extract.
**LookML** – compute `is_stockout` and `has_demand` as yesno dimensions on a latest-snapshot
SKU-location derived table, then
`measure: stockout_rate { type: number sql: 1.0 * ${count_stockout} / NULLIF(${count_with_demand},0) ;; }`.
