---
name: finance-ap-spend-dashboard
description: Designs and builds an Accounts Payable and spend dashboard — open and overdue AP, AP aging, DPO, on-time payment rate, early-payment discounts captured, invoice processing cycle time, invoices on hold, duplicate-payment risk and spend by supplier — in Power BI, Tableau or Looker. Use this skill whenever the user asks for an AP, payables, vendor payments, procure-to-pay (P2P) back-office, invoice processing, DPO, working capital or supplier payment dashboard or semantic model, even if they only say "what do we owe suppliers".
---

# Finance — Accounts Payable and Spend Dashboard

Helps the controller and AP team manage cash outflow and process health: what we owe, what is
due soon, whether we pay on time without paying too early, and where invoice processing gets
stuck.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; DPO method (default: ending AP ÷ COGS of last 90 days × 90;
   alternative: ÷ total purchases); aging basis (days past due); payment-term target (pay on due
   date, not early); whether invoice workflow statuses (received, approved, on hold, paid) are
   available; currency.
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- How much cash goes out in the next 7/30 days, and is it in line with the cash plan?
- Are we paying late (supplier risk, late fees) or too early (lost working capital)?
- Which discounts are we missing?
- Where are invoices stuck, and which approvers or suppliers cause holds?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_ap_invoices` | Supplier invoice | invoice_id, supplier_key, invoice_date, received_date, approved_date, due_date, paid_date, amount, currency, po_number, status, hold_reason, discount_terms, discount_amount_available, discount_taken |
| `fact_ap_open_items` | Open invoice × snapshot date | snapshot_date, invoice_id, open_amount, days_past_due, is_month_end_snapshot |
| `fact_ap_payments` | Payment line | payment_id, invoice_id, payment_date, amount, method |
| `dim_supplier` | Supplier | supplier_key, name, category, country, payment_terms_days, is_critical, is_small_business |
| `dim_entity`, `dim_business_unit`, `dim_date` | | |

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Open AP, Overdue AP | Context / No | L1 |
| Due next 7 / 30 days | Context | L1 |
| DPO | Context (target band) | L1 |
| On-time Payment % | Yes | L1 |
| Early Payment % | No | L2 |
| Discount Capture % | Yes | L1 |
| Invoice Cycle Time (receipt → approval → payment) | No | L1/L2 |
| Invoices on Hold (count, value) | No | L2 |
| PO-backed Invoice % (PO compliance) | Yes | L2 |
| Touchless / first-pass match % | Yes | L2 |
| Potential Duplicate Invoices | No | L2/L3 |

## Pages

**Page 1 — Payables Overview (L1)**
```
Header: "Accounts Payable" · as-of snapshot · currency · entity scope
Row 1: KPIs: Open AP | Due next 30 days | DPO (vs target band) | On-time Payment % | Discount Capture % | Avg Invoice Cycle Time
Row 2: Cash-out schedule (8 cols): AP due by week for next 8 weeks (stacked: not due / overdue carried)
       AP aging buckets (4 cols)
Row 3: On-time vs early vs late payment % by month, 13 months (6 cols)
       Top 10 suppliers by open AP (6 cols)
```

**Page 2 — Process Efficiency (L2)**
- Funnel: received → matched → approved → scheduled → paid with median days per stage.
- Ranked bar: invoices on hold by hold reason (price variance, missing receipt, no PO…).
- Table: approver | pending invoices | value | median days pending.
- Trend: PO-backed % and touchless % by month.

**Page 3 — Supplier Spend (L2)**
- Ranked bar: spend by supplier (top 15 + Other); treemap by spend category.
- Table: supplier | spend YTD | open AP | on-time % | discounts missed.

**Page 4 — Invoice Detail and Duplicate Risk (L3)**
- Exception table of overdue, on-hold and possible duplicate invoices (same supplier, amount,
  invoice number similarity, dates within 30 days) with reason column and ERP link.

## Drill paths and filters
- Supplier category → Supplier → Invoice.
- Entity → Business unit → Cost center (if invoices carry coding).
- Filters: snapshot month, entity, supplier category, payment status, critical suppliers only.

## Domain rules and gotchas
- **Open AP is semi-additive**; use period-end snapshots.
- **On-time definition:** paid on or before due date. Paying more than N days (default 5)
  before due without a discount counts as "early", which is a working-capital loss — show it.
- **Cycle time** uses received date (not invoice date, which suppliers control). Use medians in
  tooltips alongside averages; long-tail outliers distort averages.
- **Discount capture** = discounts taken ÷ discounts available on invoices paid in period.
- **Duplicates:** flag candidates, never assert duplicates; the AP team confirms.
- **Debit memos/credits** reduce open AP; keep them out of aging buckets or in a Credits bucket.
- **Sensitive data:** bank details and personal payee information must not be modeled.

## Platform notes
- **Power BI:** multiple role-playing dates on invoices (invoice, received, due, paid) — one
  active relationship (due date for aging, paid date for payment KPIs) plus `USERELATIONSHIP`.
- **Tableau:** relate payments to invoices on invoice_id; cycle-time calcs as row-level
  `DATEDIFF('day', [Received Date], [Paid Date])` aggregated with MEDIAN.
- **Looker:** `dimension_group: type: duration` for cycle times (`sql_start`, `sql_end`) gives
  days/weeks automatically; median via `type: median`.

## Done when
- [ ] Open AP at month-end ties to the AP control account.
- [ ] Cash-out schedule totals equal open AP not yet paid.
- [ ] On-time / early / late percentages sum to 100% for paid invoices.
- [ ] `bi-dashboard-design` acceptance checklist passes.
