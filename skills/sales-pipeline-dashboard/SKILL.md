---
name: sales-pipeline-dashboard
description: Designs and builds a sales pipeline and forecast dashboard — bookings vs quota, open pipeline, weighted pipeline, pipeline coverage, win rate, average deal size, sales cycle length, stage conversion, pipeline velocity, slipped and pushed deals and forecast accuracy by rep, team and region — in Power BI, Tableau or Looker over CRM data such as Salesforce or HubSpot. Use this skill whenever the user asks for a sales, pipeline, opportunity, bookings, quota attainment, forecast, revenue operations (RevOps), funnel or rep performance dashboard or semantic model.
---

# Sales — Pipeline and Forecast Dashboard

Answers the questions sales leaders ask every Monday: will we hit the number, is there enough
pipeline for next quarter, and which deals and reps need attention.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; CRM source (Salesforce, HubSpot, Dynamics); fiscal quarters;
   bookings definition (default: Closed Won amount on close date; for subscription: ACV or
   ARR — confirm); stage probabilities (default: CRM stage probability; alternative: historical
   stage-to-win rates); forecast categories (Commit, Best Case, Pipeline, Omitted); whether
   opportunity history / snapshots exist (needed for slippage and pipeline change).
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- Will we hit the quarter (bookings + commit vs quota)?
- Is pipeline coverage enough for this and next quarter, and where is it thin?
- Which deals slipped or are at risk, and which reps or stages are the bottleneck?
- Is the forecast trustworthy (forecast accuracy over time)?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_opportunities` | Opportunity (current state) | opportunity_id, account_key, owner_key, created_date, close_date, stage, stage_order, probability, forecast_category, amount, is_won, is_closed, type (new, expansion, renewal), lead_source |
| `fact_opportunity_snapshots` | Opportunity × weekly snapshot | snapshot_date, opportunity_id, stage, amount, close_date, forecast_category |
| `fact_stage_history` (optional) | Stage change | opportunity_id, from_stage, to_stage, changed_date |
| `fact_quota` | Rep × fiscal period | owner_key, fiscal_period, quota_amount |
| `dim_owner` | Sales rep with hierarchy | owner_key, name, team, manager, region, segment, role, is_active |
| `dim_account` | Customer account | account_key, name, industry, segment, region |
| `dim_date` | Day with fiscal quarter | |

Without snapshots, slippage and pipeline-change metrics cannot be computed reliably; say so
and recommend a weekly snapshot job.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Bookings (Closed Won) | Yes | L1 |
| Quota Attainment % | Yes | L1 |
| Forecast (Bookings + Commit, + Best Case) | Context | L1 |
| Open Pipeline (this / next quarter) | Yes | L1 |
| Pipeline Coverage (x) | Yes (target ≈ 3x) | L1 |
| Win Rate % | Yes | L1 |
| Average Deal Size | Yes | L2 |
| Sales Cycle (days) | No | L2 |
| Stage Conversion % | Yes | L2 |
| Pipeline Velocity ($/day) | Yes | L2 |
| Slipped Deals (count, $) | No | L2 |
| Forecast Accuracy % | Yes | L2 |
| Pipeline Created | Yes | L2 |

## Pages

**Page 1 — Sales Overview (L1)**
```
Header: "Sales Performance" · fiscal quarter (to date) · currency · team scope · CRM data as of <date>
Row 1: KPIs: Bookings QTD (vs quota) | Attainment % | Forecast (Commit) vs Quota | Pipeline Coverage (rest of quarter) | Win Rate % (trailing 4Q) | Next-Quarter Pipeline (vs target coverage)
Row 2: Bookings cumulative by week vs quota line and prior quarter (8 cols) | Forecast categories stacked bar: Won / Commit / Best Case / Pipeline vs quota (4 cols)
Row 3: Attainment by team/region, bullet (6 cols) | Top 10 open deals closing this quarter with stage, owner, days in stage (6 cols)
```

**Page 2 — Pipeline Health (L2)**
- Funnel/stage bar: open pipeline by stage with stage conversion % and average days in stage.
- Pipeline created by month and source; aging of open pipeline (days since created).
- Waterfall: pipeline at start of quarter → created → won → lost → slipped out → pulled in →
  current (requires snapshots).

**Page 3 — Rep Performance (L2)**
- Table per rep: quota, bookings, attainment %, pipeline coverage, win rate, average deal
  size, cycle days; conditional formatting on attainment.
- Scatter: win rate vs average deal size, sized by pipeline.

**Page 4 — Deal Detail (L3)**
- Opportunity table: account, opportunity, owner, stage, amount, close date, forecast
  category, days in stage, # close-date pushes, next step; CRM link.

## Drill paths and filters
- Region → Team → Rep → Opportunity.
- Segment → Account → Opportunity.
- Filters: fiscal quarter (default current), region, team, segment, opportunity type
  (new/expansion/renewal), forecast category.

## Domain rules and gotchas
- **Bookings use close date; pipeline uses expected close date** of open opportunities.
  Coverage = open pipeline expected to close in the remaining period ÷ remaining quota
  (quota − bookings to date).
- **Win rate** = won ÷ (won + lost) for opportunities closed in the window; by count by
  default, show value-based as an option. Exclude opportunities closed as duplicates/junk.
- **Probability-weighted pipeline** is a planning number, not a forecast; label it.
- **Snapshots** for slippage: a deal slipped if its close date moved out of the quarter
  between snapshots while still open.
- **Quota grain** is usually rep × month or quarter; roll up through the owner hierarchy
  as of the period (reps change teams — use an effective-dated hierarchy if available).
- **Currency**: convert opportunity amounts with the CRM's dated exchange rates where present.
- **Renewals** distort new-business metrics; split by opportunity type.

## Platform notes
- **Power BI:** relate quota to owner and date (fiscal period); cumulative bookings vs quota
  with a running total measure over the fiscal week; Salesforce connector or warehouse
  replica.
- **Tableau:** Tableau has native Salesforce connectors; on Tableau Next use the CRM data
  objects in the semantic model and define Bookings, Win Rate and Coverage as semantic metrics.
- **Looker:** separate explores for current opportunities and snapshots; quota joined at
  owner × fiscal quarter through a derived table to avoid fanout.

## Done when
- [ ] Bookings for the last closed quarter match the CRM's closed-won report.
- [ ] Coverage uses remaining quota and remaining-period pipeline.
- [ ] Win rate excludes junk/duplicate closures.
- [ ] `bi-dashboard-design` acceptance checklist passes.
