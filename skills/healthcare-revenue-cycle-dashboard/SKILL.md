---
name: healthcare-revenue-cycle-dashboard
description: Designs and builds a healthcare revenue cycle management (RCM) dashboard — gross charges, net collections, net collection rate, days in A/R, A/R over 90 days, clean claim rate, first-pass resolution, denial rate by reason (CARC) and payer, point-of-service collections and cost to collect — in Power BI, Tableau or Looker, with PHI-safe design. Use this skill whenever the user asks for a revenue cycle, RCM, claims, denials, payer performance, patient financial services, hospital billing, medical billing or physician practice A/R dashboard or semantic model, even if they only mention "denials" or "claims".
---

# Healthcare — Revenue Cycle Management Dashboard

Shows whether a hospital, health system or physician group is getting paid fully and
promptly for the care it delivers, and where revenue leaks: front-end registration errors,
coding, claim submission, denials or slow follow-up.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; setting (hospital/facility vs professional billing);
   days in A/R basis (default: gross A/R ÷ average daily **gross** charges over 90 days;
   some organizations use net); denial rate basis (default: **claims** denied ÷ claims
   adjudicated; alternative: dollars); A/R aging basis (default: days from discharge/service
   date); benchmarks to show (internal targets; mention that industry benchmarks such as HFMA
   MAP Keys exist but use the customer's targets).
3. **PHI rules apply** (see below). Read `references/metrics.md`.

## Decisions this dashboard supports
- Are we collecting what we are owed (net collection rate) and how fast (days in A/R)?
- Which payers, denial reasons and departments drive denials, and which are preventable?
- Where is A/R aging beyond 90 days, and which accounts need follow-up?
- Are front-end processes (eligibility, registration, POS collections) working?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_charges` | Charge line | service_date, post_date, encounter_key, department_key, provider_key, cpt/hcpcs or revenue_code, gross_charge |
| `fact_claims` | Claim (837) submission | claim_id, encounter_key, payer_key, submit_date, claim_type (institutional/professional), billed_amount, is_clean_claim, submission_number |
| `fact_remits` | Remittance (835) line | claim_id, remit_date, paid_amount, contractual_adjustment, patient_responsibility, denial_flag, carc_code, rarc_code, group_code |
| `fact_ar_snapshot` | Account (encounter) × snapshot | snapshot_date, encounter_key, payer_key, financial_class, ar_balance, days_since_discharge, is_month_end_snapshot |
| `fact_payments` | Payment | payment_date, encounter_key, source (payer/patient), amount, is_point_of_service |
| `dim_payer` | Payer / plan | payer_key, payer_name, financial_class (Medicare, Medicaid, Commercial, Self-pay) |
| `dim_department`, `dim_provider`, `dim_facility`, `dim_date` | | |
| `dim_denial_reason` | CARC code | carc_code, description, category (eligibility, authorization, coding, medical necessity, timely filing, duplicate, other), is_preventable |

`encounter_key` is a surrogate key; patient identifiers (MRN, name, DOB) are not needed for
this dashboard and should not be in the semantic model.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Gross Charges | Context | L1 |
| Net Collections | Yes | L1 |
| Net Collection Rate % | Yes | L1 |
| Days in A/R | No | L1 |
| A/R > 90 Days % | No | L1 |
| Denial Rate % (initial) | No | L1 |
| Clean Claim Rate % | Yes | L1/L2 |
| First-Pass Resolution Rate % | Yes | L2 |
| Denial Overturn Rate % | Yes | L2 |
| POS Collection Rate % | Yes | L2 |
| Bad Debt % / Charity % of gross revenue | No | L2 |
| Cost to Collect % | No | L2 |

## Pages

**Page 1 — Revenue Cycle Overview (L1)**
```
Header: "Revenue Cycle Performance" · period · facility/group scope · data through <date> · "Aggregated data – no PHI"
Row 1: KPIs: Net Collections (vs PM) | Net Collection Rate % (vs target) | Days in A/R (vs target) | A/R > 90 % | Denial Rate % | Clean Claim Rate %
Row 2: Days in A/R and Net Collection Rate trend, 13 months (8 cols) | A/R by aging bucket and financial class, stacked (4 cols)
Row 3: Denials by category, ranked bar with preventable share (6 cols) | Denial rate by payer, top 10 (6 cols)
```

**Page 2 — Denials Management (L2)**
- Matrix: payer × denial category (claim counts and denied $), heat on denial rate.
- Trend: initial denial rate and overturn rate by month.
- Ranked bar: top CARC codes by denied dollars with description.
- Table: department/service line with denial rate and preventable denials.

**Page 3 — A/R and Follow-up (L2)**
- Aging buckets (0–30, 31–60, 61–90, 91–120, 121–180, 180+) by financial class.
- Ranked bar: A/R > 90 days by payer; trend of A/R > 90 % by month.

**Page 4 — Account Work Queue (L3, restricted)**
- Account-level table: encounter key (not MRN), payer, financial class, balance, days since
  discharge, last denial reason, follow-up owner; only for roles authorized to see account
  level, enforced by RLS/permissions.

## Drill paths and filters
- Facility → Department/service line → Provider (aggregate only).
- Financial class → Payer → Plan.
- Denial category → CARC code → Claim (L3).
- Filters: period (default last closed month), facility, financial class, payer, claim type,
  department.

## PHI and compliance rules
- Build on **aggregates** for L1/L2. No patient names, MRNs, DOBs, addresses or free-text
  notes in the semantic model; use surrogate encounter keys.
- Apply **minimum necessary**: L3 account pages only for authorized roles, enforced by
  row-level security / access grants, and documented in the spec.
- **Small-cell suppression**: hide or bucket provider/department cells with very small counts
  (default < 11) when dashboards are shared broadly.
- Never put real PHI into sample data, screenshots, PRs or prompts; use synthetic data.
- Refer HIPAA/compliance questions to the customer's privacy officer; this skill is design
  guidance, not legal advice.

## Domain rules and gotchas
- **Net collection rate** excludes contractual adjustments from the denominator but not
  denials or write-offs that should have been collected; define "allowed" consistently.
- **Denial rate denominator**: claims adjudicated in the period (initial submissions only for
  initial denial rate); resubmissions inflate counts if included.
- **Days in A/R** depends on the charge basis (gross vs net) — never compare across bases.
- **Credit balances** distort A/R totals; show them separately.
- **Payer mix shifts** change all KPIs; provide financial class breakdowns next to totals.
- Lag: remits arrive weeks after submission; label the latest month as preliminary.

## Platform notes
- **Power BI:** separate fact tables for charges, claims, remits and A/R snapshot related
  through shared dimensions (date, payer, department), not to each other; RLS role for L3.
- **Tableau:** relationships on claim_id between claims and remits; data source filter for
  access control on L3; suppression via `IF COUNTD([Encounter Key]) < 11 THEN NULL`.
- **Looker:** `access_filter` by facility; `required_access_grants` on account-level fields;
  suppression via `html:` or a SQL `CASE` in the measure.

## Done when
- [ ] Net collections reconcile to cash posting for the period.
- [ ] Denial rate denominators exclude resubmissions (for initial denial rate).
- [ ] No PHI fields in the model; L3 page protected and documented.
- [ ] `bi-dashboard-design` acceptance checklist passes.
