---
name: supply-chain-inventory-dashboard
description: Designs and builds an inventory health dashboard — on-hand value and units, inventory turns, days of supply, stockouts, excess and obsolete (E&O) stock, inventory aging, ABC classification, safety-stock coverage and cycle-count accuracy by site, SKU and category — in Power BI, Tableau or Looker. Use this skill whenever the user asks for an inventory, stock, warehouse stock, days on hand, turns, stockout, overstock, slow-moving, E&O, ABC/XYZ or working-capital inventory dashboard or semantic model, even if they only say "how much stock do we have".
---

# Supply Chain — Inventory Health Dashboard

Balances two failures: running out (lost sales, line stoppages) and holding too much
(working capital, obsolescence). The dashboard shows both on the same page so planners make
the trade-off consciously.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; inventory valuation basis (default: standard cost);
   days-of-supply basis (default: forward-looking demand forecast; fallback: trailing 90-day
   average consumption); E&O rules (default: excess = on-hand beyond 180 days of supply;
   obsolete = no movement in 365 days or flagged end-of-life); snapshot frequency; locations in
   scope (plants, DCs, stores, in-transit).
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- Where are we at risk of stockout in the next 2–4 weeks?
- Where is excess or obsolete stock tying up cash, and what should we liquidate or transfer?
- Are inventory turns improving toward target by category and site?
- Can we trust the numbers (cycle-count accuracy)?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_inventory_snapshot` | SKU × location × snapshot date | snapshot_date, item_key, location_key, on_hand_qty, on_hand_value, allocated_qty, in_transit_qty, safety_stock_qty, last_movement_date, receipt_date (for aging layers if available), is_month_end_snapshot |
| `fact_inventory_movements` | Goods movement line | movement_date, item_key, location_key, movement_type (issue, receipt, transfer, adjustment), qty, value |
| `fact_demand_forecast` | SKU × location × week/day | forecast_date, item_key, location_key, forecast_qty |
| `fact_cycle_counts` | Count event | count_date, item_key, location_key, system_qty, counted_qty |
| `dim_item` | SKU | item_key, sku, description, category, subcategory, abc_class, xyz_class, lifecycle_status, unit_cost, uom, shelf_life_days |
| `dim_location` | Plant / DC / store | location_key, name, type, region, country |
| `dim_date` | Day | |

COGS for turns comes from issues to production/sales in `fact_inventory_movements` or from
the finance P&L (`finance-pnl-dashboard`); state which.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Inventory Value (on hand) | Context | L1 |
| Inventory Turns (annualized) | Yes | L1 |
| Days of Supply (DOS) | Target band | L1 |
| Stockout Rate (SKU-locations at zero with demand) | No | L1 |
| Below Safety Stock % | No | L1 |
| E&O Value, E&O % | No | L1 |
| Inventory Aging (0–30 … 365+) | Context | L2 |
| ABC mix of value | Context | L2 |
| Cycle Count Accuracy % | Yes | L2 |
| In-transit Value | Context | L2 |

## Pages

**Page 1 — Inventory Health Overview (L1)**
```
Header: "Inventory Health" · as-of snapshot · valuation basis · currency
Row 1: KPIs: Inventory Value (vs PM) | Turns (vs target) | Days of Supply (vs target band) | Stockout Rate | Below Safety Stock % | E&O % (vs PM)
Row 2: Inventory value trend with turns overlay as separate small chart, 13 months (8 cols)
       Risk matrix (4 cols): scatter of SKU-locations — x = days of supply, y = value, quadrants Stockout risk / Healthy / Excess
Row 3: Inventory value by category vs target DOS, bullet (6 cols) | Top 10 stockout-risk SKUs table (6 cols)
```

**Page 2 — Excess, Obsolete and Aging (L2)**
- Aging buckets by value (0–30, 31–90, 91–180, 181–365, 365+).
- Ranked bar: E&O value by category/site; table of top E&O SKUs with last movement date,
  shelf life remaining and suggested action column (transfer / liquidate / write down).

**Page 3 — Availability and Replenishment (L2)**
- Heat matrix: category × site, colored by days of supply versus target band.
- Trend: stockout rate and below-safety-stock % by week (12 weeks).
- Table: SKU-location below safety stock with open PO quantity and next receipt date.

**Page 4 — SKU-Location Detail (L3)**
- Movement history chart (receipts vs issues by week), projected on-hand vs forecast, table of
  recent movements and cycle counts.

## Drill paths and filters
- Category → Subcategory → SKU → SKU-location.
- Region → Site → Storage location (if modeled).
- Filters: snapshot date (default latest), site/region, category, ABC class, lifecycle status,
  include/exclude in-transit and consignment.

## Domain rules and gotchas
- **On-hand is semi-additive**: never sum across snapshots. Average inventory for turns =
  average of period-end snapshots across the period.
- **Turns** = annualized COGS ÷ average inventory value; both at cost. Don't mix retail-price
  sales with cost inventory.
- **Days of supply** at aggregate levels = Σ on-hand ÷ Σ average daily demand, not average of
  SKU DOS; cap displays at a sensible maximum (e.g. 999) and treat zero demand as "no demand"
  rather than infinite.
- **Stockout definition** requires demand: an item at zero with no demand is not a stockout.
- **Units of measure**: never sum quantities across different UOMs; aggregate value or
  convert to a base UOM.
- **Negative on-hand** (posting errors) must be surfaced as a data-quality exception, not
  netted silently.
- **Consignment and in-transit** stock: decide inclusion explicitly and show it in the header.

## Platform notes
- **Power BI:** `LASTNONBLANK` snapshot pattern for on-hand; average inventory via
  `AVERAGEX` over month-end snapshots; scatter visual for the risk matrix with constant lines.
- **Tableau:** period-end snapshot flag; risk matrix as a scatter with reference lines at DOS
  targets; parameter for E&O threshold days.
- **Looker:** filter balance measures on `is_period_end`; E&O threshold as a `parameter`
  with `{% parameter %}` in the dimension SQL.

## Done when
- [ ] Month-end inventory value ties to the inventory GL balance (difference explained:
      in-transit, consignment, reserves).
- [ ] Turns and DOS recompute correctly at total level (not averaged).
- [ ] No negative quantities hidden; data-quality exceptions listed.
- [ ] `bi-dashboard-design` acceptance checklist passes.
