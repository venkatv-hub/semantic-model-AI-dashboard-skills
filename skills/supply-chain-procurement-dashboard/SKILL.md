---
name: supply-chain-procurement-dashboard
description: Designs and builds a procurement and supplier performance dashboard — spend under management, PO coverage, contract compliance, maverick spend, purchase price variance (PPV), savings, supplier on-time delivery, quality (defect PPM), lead time and supplier concentration risk — in Power BI, Tableau or Looker. Use this skill whenever the user asks for a procurement, purchasing, sourcing, spend analytics, supplier scorecard, vendor performance, PPV, category management or source-to-pay dashboard or semantic model, even if they only say "how are our suppliers doing".
---

# Supply Chain — Procurement and Supplier Performance Dashboard

Gives the CPO and category managers control over what is bought, from whom, at what price,
and how well suppliers deliver — the inputs to sourcing decisions and supplier reviews.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; spend basis (default: invoice amount by invoice date;
   alternative: PO amount by PO date); category taxonomy (UNSPSC or internal); PPV baseline
   (default: standard cost; alternatives: last price paid, contract price, prior-year average);
   supplier OTD reference (default: PO line confirmed delivery date); savings methodology if
   savings are tracked.
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- How much spend is under management (on contract, through POs) and where is maverick spend?
- Are we paying more than baseline (PPV), and which categories/suppliers drive it?
- Which suppliers are underperforming on delivery or quality and need a business review?
- Where are we over-dependent on single suppliers?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_spend` | Invoice line (or PO line) | invoice_date, supplier_key, category_key, cost_center_key, amount, quantity, unit_price, po_number, contract_id |
| `fact_po_lines` | Purchase order line | po_number, line, supplier_key, item_key, order_date, confirmed_date, ordered_qty, unit_price, standard_cost |
| `fact_receipts` | Goods receipt line | po_number, line, receipt_date, received_qty, rejected_qty |
| `dim_supplier` | Supplier (with parent) | supplier_key, name, parent_supplier, country, risk_tier, diverse_flag, preferred_flag |
| `dim_category` | Spend category hierarchy | category_key, level1, level2, level3, category_manager |
| `dim_contract` (optional) | Contract | contract_id, supplier_key, start_date, end_date, contracted_price |
| `dim_item`, `dim_cost_center`, `dim_date` | | |

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Total Spend | Context | L1 |
| Spend Under Management % | Yes | L1 |
| PO Coverage % | Yes | L1 |
| Maverick Spend | No | L1 |
| PPV (value and %) | Lower (negative = favorable) | L1 |
| Supplier OTD % | Yes | L1 |
| Supplier Defect Rate (PPM) | No | L2 |
| Average Lead Time / Lead Time Variability | No | L2 |
| Supplier Concentration (top-1 share per category) | No | L2 |
| Active Suppliers count, Spend per Supplier | Context | L2 |

## Pages

**Page 1 — Procurement Overview (L1)**
```
Header: "Procurement Performance" · period · spend basis · currency
Row 1: KPIs: Total Spend (vs PY) | Spend Under Mgmt % | PO Coverage % | PPV % (vs target) | Supplier OTD % | Maverick Spend
Row 2: Spend trend by month with PY (8 cols) | Spend by category level 1, 100% bar or treemap (4 cols)
Row 3: PPV waterfall by category, baseline → actual (6 cols) | Suppliers below OTD target table (6 cols)
```

**Page 2 — Spend Analysis (L2)**
- Treemap/ranked bar: spend by category level 2 → supplier (drill).
- Pareto: cumulative spend % by supplier (how many suppliers make up 80% of spend).
- Matrix: category × business unit spend with PO coverage % heat.

**Page 3 — Supplier Scorecard (L2)**
- Table per supplier: spend, OTD %, defect PPM, average lead time, PPV %, risk tier, trend
  arrows vs prior quarter; composite score (weights stated in the tooltip).
- Scatter: OTD % (x) vs defect PPM (y), sized by spend, quadrant lines at targets.

**Page 4 — PO and Receipt Detail (L3)**
- PO lines with confirmed vs actual receipt date, days late, quantity received/rejected,
  price vs baseline; link to the ERP PO.

## Drill paths and filters
- Category L1 → L2 → L3 → Supplier → PO line.
- Supplier parent → Supplier site.
- Filters: period (default trailing 12 months for spend, last quarter for scorecard),
  business unit, category manager, supplier risk tier, preferred suppliers only.

## Domain rules and gotchas
- **Supplier normalization:** the same supplier often appears under several vendor IDs; group
  by `parent_supplier` before ranking or concentration analysis.
- **PPV sign:** PPV = (actual price − baseline price) × quantity; positive = paid more =
  unfavorable. Use quantity received/invoiced, and the same UOM and currency for both prices.
- **Spend under management** needs an agreed definition (on contract OR through a catalog OR
  sourced by procurement). Put the definition in the tooltip.
- **Maverick spend** = spend without PO or off-contract with a preferred supplier available;
  exclude legitimately non-PO categories (utilities, taxes, payroll-related) via a category
  flag.
- **OTD** uses confirmed date and receipt date; partial receipts count as late until the last
  quantity is received (consistent with `supply-chain-order-fulfillment-dashboard` logic).
- **Defect PPM** = rejected qty ÷ received qty × 1,000,000; low volumes create noise — show
  received volume beside it.

## Platform notes
- **Power BI:** Pareto with a cumulative % measure using `RANKX` and a running total;
  composite score via a field parameter for weights is overkill — keep weights fixed and
  documented.
- **Tableau:** Pareto with a RUNNING_SUM table calc ÷ TOTAL; set actions for category drill.
- **Looker:** Pareto via a derived table with window functions; supplier scorecard as a
  `looker_grid` with conditional formatting.

## Done when
- [ ] Total spend reconciles to AP invoice totals for the period (difference explained:
      non-PO categories, credit notes, intercompany).
- [ ] PPV uses consistent UOM and currency (spot-check three items).
- [ ] Supplier names are normalized to parent in rankings.
- [ ] `bi-dashboard-design` acceptance checklist passes.
