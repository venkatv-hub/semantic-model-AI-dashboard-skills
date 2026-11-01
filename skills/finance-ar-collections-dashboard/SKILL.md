---
name: finance-ar-collections-dashboard
description: Designs and builds an Accounts Receivable and collections dashboard — total and overdue AR, aging buckets, DSO, collection effectiveness index (CEI), disputes, cash collected and collector worklists — in Power BI, Tableau or Looker. Use this skill whenever the user asks for an AR, receivables, aging report, DSO, collections, credit control, cash application or order-to-cash (O2C) dashboard or semantic model, even if they only mention "overdue invoices" or "who owes us money".
---

# Finance — Accounts Receivable and Collections Dashboard

Shows how much customers owe, how late they are, whether collections are improving, and
exactly which invoices collectors should chase today.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; DSO method (default: **count-back**; alternative: standard
   90-day); aging basis (default: days past **due date**; alternative: days since invoice date);
   bucket edges (default Current, 1–30, 31–60, 61–90, 91–120, 120+); DSO target; whether
   disputes are tracked; snapshot frequency (daily or month-end).
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- Is cash collection keeping pace with sales (DSO, CEI trends)?
- Which customers and invoices should be escalated this week?
- Which collectors or regions have deteriorating aging?
- How much AR is at risk of write-off (90+ and disputed)?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_ar_open_items` | Open invoice × snapshot date (daily or month-end) | snapshot_date, invoice_id, customer_key, invoice_date, due_date, open_amount, original_amount, currency, dispute_flag, is_month_end_snapshot |
| `fact_ar_transactions` | Invoice / credit note / payment / adjustment line | transaction_date, type, invoice_id, customer_key, amount, payment_date |
| `dim_customer` | Bill-to customer | customer_key, name, parent_account, segment, region, credit_limit, payment_terms_days, collector |
| `dim_collector` (optional) | Collector | collector_key, name, team, manager |
| `dim_business_unit` | | business_unit_key, name |
| `dim_date` | Day | date, month, fiscal attributes |

If there is no snapshot table, the open balance at a date can be reconstructed from
transactions (invoices − payments − credits with date ≤ snapshot), but recommend building a
snapshot table in the warehouse; reconstructing in the BI layer is slow and error-prone.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Total AR | Context | L1 |
| Overdue AR, Overdue % | No | L1 |
| DSO (count-back) | No | L1 |
| CEI (collection effectiveness index) | Yes | L1 |
| Cash Collected | Yes | L1 |
| AR 90+ %, Disputed AR | No | L1/L2 |
| Average Days to Pay, Average Days Late | No | L2 |
| % of customers over credit limit | No | L2 |
| Promise-to-pay kept % (if tracked) | Yes | L2 |

## Pages

**Page 1 — AR Overview (L1)**
```
Header: "Receivables & Collections" · as-of snapshot date · currency · BU scope
Row 1: KPI cards: Total AR (vs PM) | Overdue % (vs PM) | DSO (vs target) | CEI (vs PM) | Cash Collected (vs PM) | AR 90+ % (vs PM)
Row 2: DSO trend vs target, 13 months (8 cols) | Aging buckets column chart (4 cols, fixed order)
Row 3: Overdue AR by region/BU, ranked bar (6 cols) | Top 10 overdue customers table (6 cols): customer, overdue, oldest days, collector
```

**Page 2 — Aging Analysis (L2)**
- Matrix: rows = Region → Customer, columns = aging buckets + Total + % 90+, heat on % 90+.
- 100% stacked bar: aging mix by month (13 months) to show deterioration.
- Disputed AR by dispute reason (ranked bar), with average dispute age.

**Page 3 — Collector Performance (L2)**
- Table per collector: assigned AR, overdue %, CEI, cash collected, # accounts, change vs PM.
- Bullet chart: cash collected vs collection target by collector.

**Page 4 — Customer Worklist (L3, drill-through on customer or collector)**
- Exception table: invoice, invoice date, due date, days past due, open amount, dispute
  status, last contact date, collector; sorted by severity score (open amount × days past due
  weight); URL action to the ERP invoice.
- Customer header cards: credit limit, utilization %, payment terms, average days to pay.

## Drill paths and filters
- Region → Customer parent → Customer → Invoice.
- Collector team → Collector → Customer → Invoice.
- Filters: snapshot month (default latest month-end), business unit, region, collector,
  customer segment, include/exclude disputed.

## Domain rules and gotchas
- **AR is a balance (semi-additive).** Sum open amount at one snapshot; never across
  snapshots. Trends use month-end snapshots.
- **Credit balances.** Unapplied cash and credit notes are negative open items; show Total AR
  net, and optionally "Gross AR" and "Unapplied Cash" separately. Exclude credit balances from
  aging buckets or put them in their own "Credits" bucket.
- **Days past due** = snapshot_date − due_date (≤ 0 means Current). Compute at the snapshot
  date, not today, or history will shift.
- **DSO method matters.** Count-back DSO handles seasonality; standard DSO is simpler. Never
  mix methods across periods. Use credit sales only (exclude cash sales) in the denominator.
- **Currency.** Revalue open items at the snapshot's rate or use the stored reporting amount;
  state which.
- **Customer hierarchy.** Collections act at parent-account level for large customers;
  aggregate by parent where the data supports it.
- **Write-offs** reduce AR without cash; track them as a separate metric so CEI isn't
  inflated.

## Platform notes
- **Power BI:** `Total AR` with `LASTNONBLANK` snapshot logic; count-back DSO needs an
  iterative measure (see metrics.md); aging bucket sort column.
- **Tableau:** use the period-end snapshot flag calc; count-back DSO is easier precomputed in
  the warehouse at customer × month and then aggregated as Σ(AR) ÷ weighted daily sales.
- **Looker:** `filters: [is_period_end: "yes"]` on balance measures; consider a derived table
  for monthly credit sales to compute DSO.

## Done when
- [ ] Total AR at the latest month-end ties to the AR sub-ledger / trial balance control
      account.
- [ ] Aging buckets sum to Total AR (or the difference equals the credits bucket).
- [ ] DSO method and target are shown in the KPI tooltip.
- [ ] The worklist opens from a customer click with the right filters.
- [ ] `bi-dashboard-design` acceptance checklist passes.
