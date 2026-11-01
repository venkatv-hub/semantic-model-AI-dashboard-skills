---
name: supply-chain-order-fulfillment-dashboard
description: Designs and builds an order fulfillment and logistics dashboard — OTIF (on time in full), on-time delivery, fill rate, perfect order rate, order cycle time, backorders, late shipments, carrier performance and freight cost per unit — in Power BI, Tableau or Looker. Use this skill whenever the user asks for an OTIF, delivery performance, order-to-delivery, fulfillment, shipping, logistics, distribution center, carrier, customer service level or backorder dashboard or semantic model, even if they only say "are we delivering on time".
---

# Supply Chain — Order Fulfillment and OTIF Dashboard

Measures the promise the business makes to customers: the right quantity, on the agreed date,
at a sensible cost — and pinpoints where in the order-to-delivery chain failures start.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; **on-time reference date** (default: customer requested
   date; alternatives: first promised/confirmed date, latest promised date); on-time window
   (default: delivered on the date, 0 days early/late tolerance; retail customers often use
   −1/+0); in-full basis (default: order-line quantity, 100%); measurement point (delivery
   proof vs ship date + transit); grain for OTIF (order line by default).
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- Are we meeting customer service-level commitments (OTIF) overall and for key accounts?
- Is failure caused by lateness or by short shipments — and in which DC, carrier or product?
- Which open orders are at risk of missing their date today and this week?
- Is freight cost per unit trending up?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_order_lines` | Sales order line | order_id, line_id, customer_key, item_key, ship_from_location_key, order_date, requested_date, promised_date, ordered_qty, order_value, status |
| `fact_shipments` | Shipment / delivery line (one order line may ship in many) | shipment_id, order_id, line_id, ship_date, delivered_date, shipped_qty, carrier_key, freight_cost, is_delivered |
| `dim_customer` | Ship-to / sold-to | customer_key, name, segment, key_account_flag, region, channel |
| `dim_item` | Product | item_key, sku, category, abc_class |
| `dim_location` | DC / plant | location_key, name, region |
| `dim_carrier` | Carrier / mode | carrier_key, name, mode (parcel, LTL, FTL, ocean) |
| `dim_date` | Day | |

Pre-aggregate shipments to order-line level in the warehouse (first ship date, last delivered
date, total shipped qty) as `fact_order_line_fulfillment`; OTIF logic is far simpler and
faster there.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| OTIF % | Yes | L1 |
| On-time % (OT) | Yes | L1 |
| In-full % (IF) | Yes | L1 |
| Fill Rate (units) | Yes | L1 |
| Order Cycle Time (order → delivered) | No | L1 |
| Backorder Value | No | L1 |
| Perfect Order % | Yes | L2 |
| Late Lines (count) and Average Days Late | No | L2 |
| Carrier On-time % | Yes | L2 |
| Freight Cost per Unit / % of Revenue | No | L2 |

## Pages

**Page 1 — Fulfillment Overview (L1)**
```
Header: "Order Fulfillment" · delivery period · OTIF basis (requested date, line level) · scope
Row 1: KPIs: OTIF % (vs target) | On-time % | In-full % | Fill Rate | Order Cycle Time (days) | Backorder Value
Row 2: OTIF, OT and IF trend by week, 13 weeks or months (8 cols)
       Failure split (4 cols): stacked bar of failed lines — late only / short only / late and short
Row 3: OTIF by DC ranked bar vs target (6 cols) | Key accounts below OTIF target table (6 cols)
```

**Page 2 — Root Cause (L2)**
- Matrix: DC × product category, OTIF % with heat formatting and line counts.
- Late reasons (if captured: stock unavailable, carrier delay, warehouse capacity, credit hold)
  as ranked bar; average days late histogram.
- Cycle time breakdown: order → release → pick → ship → deliver median days (horizontal
  stacked bar).

**Page 3 — Logistics and Carriers (L2)**
- Carrier scorecard table: shipments, on-time %, damage/claims rate, freight cost per unit,
  change vs prior period.
- Freight cost per unit trend by mode.

**Page 4 — Order Risk Worklist (L3)**
- Open order lines due in the next 7 days with available stock < open quantity, or not yet
  picked within the standard lead time; columns: order, customer, item, due date, open qty,
  available qty, DC, status; sorted by due date and order value.

## Drill paths and filters
- Region → DC → Customer → Order → Line.
- Category → SKU.
- Filters: delivery period (default last complete week or month), DC, customer segment, key
  accounts only, channel, carrier.

## Domain rules and gotchas
- **Measure on the due date, not the order date.** Lines enter OTIF in the period their
  reference date falls in; open lines past due count as failures (late) as soon as the date has
  passed, otherwise late orders disappear from the metric.
- **Reference date is a business choice.** Requested-date OTIF is customer-centric; promised-
  date OTIF measures execution. Show which one in the header and never mix.
- **Split shipments:** a line is in full only if total delivered qty ≥ ordered qty by the
  reference date (within tolerance). On time uses the delivery of the *last* shipment needed to
  complete the line, or the first shipment if the business measures "first delivery".
- **Cancelled lines** are excluded; customer-requested reschedules update the reference date
  only if the business agrees (track a "reschedule reason").
- **Fill rate** (units shipped ÷ units ordered) can look healthy while OTIF is poor; show both.
- **Weekend/holiday calendars**: on-time comparisons use calendar days unless the customer
  contract uses business days.

## Platform notes
- **Power BI:** use the line-level fulfillment table; OTIF as `DIVIDE` of flag sums; active
  relationship on the reference (requested) date.
- **Tableau:** relationship between order lines and shipments on order_id + line_id would
  require LOD to roll up; prefer the pre-aggregated line table.
- **Looker:** base explore on the line fulfillment table; `yesno` dimensions for on_time and
  in_full, and `type: count` measures with filters.

## Done when
- [ ] OTIF line counts reconcile to the order book for the period (cancelled excluded).
- [ ] Past-due open lines are counted as failures.
- [ ] OTIF ≤ min(OT %, IF %) for every slice (sanity check).
- [ ] `bi-dashboard-design` acceptance checklist passes.
