---
name: hr-workforce-dashboard
description: Designs and builds an HR and workforce analytics dashboard — headcount and FTE, hires, terminations, attrition and voluntary/regretted turnover, retention, time to fill, offer acceptance, internal mobility, span of control, absenteeism and workforce composition with privacy-safe aggregation and row-level security — in Power BI, Tableau or Looker. Use this skill whenever the user asks for an HR, people analytics, workforce, headcount, attrition, turnover, retention, hiring, recruiting funnel, talent acquisition or DEI dashboard or semantic model, even if they only say "how many people left".
---

# HR — Workforce and Attrition Dashboard

Gives HR business partners and leaders an accurate, privacy-safe view of the workforce:
how big it is, how it is changing, who is leaving and why, and how quickly roles are filled.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; headcount definition (default: active employees on the last
   day of the period, excluding contractors and interns — confirm); attrition formula (default:
   terminations ÷ average headcount, annualized on rolling 12 months); which terminations are
   voluntary and regretted; organizational hierarchy source and whether it is effective-dated;
   minimum group size for display (default: 5).
3. Privacy rules apply (see below). Read `references/metrics.md`.

## Decisions this dashboard supports
- Is headcount tracking the approved plan by organization?
- Where is attrition rising, especially voluntary and regretted, and in which tenure bands?
- Are we filling roles fast enough, and where does the hiring funnel leak?
- Are spans of control and internal mobility healthy?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_employee_snapshot` | Employee × month-end (or daily) | snapshot_date, employee_key, org_unit_key, job_key, location_key, manager_key, employment_type, fte, status, hire_date, tenure_months, grade, is_month_end_snapshot |
| `fact_employee_events` | HR event | event_date, employee_key, event_type (hire, rehire, termination, transfer, promotion), termination_type (voluntary/involuntary), is_regretted, reason_code |
| `fact_requisitions` | Job requisition | requisition_id, org_unit_key, job_key, opened_date, filled_date, status, hiring_manager_key |
| `fact_applications` | Candidate application stage events | application_id, requisition_id, stage, stage_date, outcome |
| `fact_headcount_plan` | Org unit × month | org_unit_key, month, planned_headcount |
| `dim_org_unit` | Organization hierarchy (effective-dated if possible) | org_unit_key, level1…level4, leader, cost_center |
| `dim_job`, `dim_location`, `dim_date` | | |

Do not bring names, national IDs, salary detail, medical/leave reasons or demographic fields at
employee level into broadly shared models. Demographics for workforce composition are
aggregated and governed (see privacy rules).

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Headcount (period end), FTE | Context | L1 |
| Headcount vs Plan | Context | L1 |
| Hires, Terminations | Context | L1/L2 |
| Attrition Rate % (rolling 12M) | No | L1 |
| Voluntary Attrition %, Regretted Attrition % | No | L1 |
| First-Year Attrition % | No | L2 |
| Time to Fill (median days) | No | L1 |
| Offer Acceptance Rate % | Yes | L2 |
| Internal Mobility Rate % | Yes | L2 |
| Span of Control (avg direct reports) | Target band | L2 |
| Open Requisitions | Context | L2 |

## Pages

**Page 1 — Workforce Overview (L1)**
```
Header: "Workforce Overview" · as of period end · employees only (excl. contractors) · org scope
Row 1: KPIs: Headcount (vs plan) | Net Change (hires − terms, period) | Attrition % R12M (vs PY) | Voluntary Attrition % | Regretted Attrition % | Time to Fill (median days)
Row 2: Headcount trend vs plan, 13 months (8 cols) | Headcount bridge waterfall: start → hires → terminations → transfers in/out → end (4 cols)
Row 3: Attrition % by org unit (level 2), ranked bar vs company average (6 cols) | Attrition by tenure band (0–1y, 1–3y, 3–5y, 5y+) (6 cols)
```

**Page 2 — Attrition Deep Dive (L2)**
- Trend: voluntary vs involuntary attrition R12M by month.
- Ranked bar: top termination reasons (voluntary), with regretted share.
- Matrix: org unit × job family attrition with suppression for small groups.

**Page 3 — Talent Acquisition (L2)**
- Funnel: applications → screen → interview → offer → accepted, with conversion %.
- Time to fill by job family (median), open requisitions aging buckets.
- Offer acceptance trend.

**Page 4 — Organization Health (L2)**
- Span of control distribution (histogram of direct reports per manager).
- Internal mobility rate by org unit; promotions per 100 employees.

**Page 5 — Restricted Detail (L3, HRBP only)**
- Employee-level list (employee ID, org, job, tenure, status, termination reason) only for
  authorized HR roles via RLS; never in broadly shared dashboards.

## Drill paths and filters
- Org level 1 → level 2 → level 3 → team (manager).
- Job family → job.
- Region → country → location.
- Filters: period (default last closed month), org unit, location, employment type, job
  family. RLS restricts managers to their own organization.

## Privacy and governance rules
- **Minimum group size**: suppress metrics for groups with fewer than 5 employees (configurable)
  to avoid identifying individuals, especially for attrition and composition cuts.
- **Row-level security** by organization: leaders see their own subtree; HRBPs see assigned
  orgs; executives see all.
- **Sensitive attributes** (gender, ethnicity, age, disability, salary) only in aggregated,
  governed views with explicit approval; follow local law (e.g. GDPR) and the customer's HR
  data policy.
- Never use real employee data in examples, screenshots or PRs.

## Domain rules and gotchas
- **Headcount is a snapshot** (semi-additive); hires and terminations are flows (additive).
- **Attrition denominator** = average of month-end headcounts over the window (12 months
  for R12M), not the period-end headcount.
- **Bridge must reconcile**: start + hires + transfers in − terminations − transfers out = end;
  differences point at data-quality issues (e.g. backdated events).
- **Effective dating**: report employees under the org they belonged to at the time of the
  event unless the user asks for "current organization" restatement.
- **Rehires** count as hires; define whether internal transfers count as attrition at the
  org-unit level (default: yes for the unit, no for company totals).
- **Contractors** excluded unless asked; show the scope in the header.

## Platform notes
- **Power BI:** month-end snapshot pattern for headcount; R12M attrition with `DATESINPERIOD`;
  RLS with a dynamic security table mapping user → org units; suppression via measure.
- **Tableau:** user filter / entitlement table for RLS; suppression calc on every
  sensitive view; bridge waterfall with Gantt bars.
- **Looker:** `access_filter` on org unit with a user attribute; suppression `CASE` in
  measures; restricted fields behind `required_access_grants`.

## Done when
- [ ] Headcount at period end ties to the HRIS headcount report.
- [ ] Headcount bridge reconciles (or differences are listed).
- [ ] Small groups suppressed; RLS tested with at least two test users.
- [ ] `bi-dashboard-design` acceptance checklist passes.
