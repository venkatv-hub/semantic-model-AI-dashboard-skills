---
name: finance-pnl-dashboard
description: Designs and builds a Profit & Loss / FP&A performance dashboard — revenue, gross margin, operating expenses, EBITDA and net income versus budget, forecast and prior year, with variance bridges and cost-center drill-down — in Power BI, Tableau or Looker. Use this skill whenever the user asks for a P&L, income statement, financial performance, budget vs actual, BvA, variance analysis, management accounts, month-end close or CFO dashboard, or wants a finance semantic model over a general ledger, even if they don't say "P&L".
---

# Finance — P&L and Budget vs Actual Dashboard

Gives the CFO and finance business partners one trusted view of financial performance:
are we hitting plan, what drove the variance, and which cost centers or accounts need a
conversation. Built on general-ledger actuals plus budget/forecast.

## Before you start
1. Read the `bi-dashboard-design` skill (layout, components, spec format) and the builder skill
   for the target platform (`powerbi-dashboard-builder`, `tableau-dashboard-builder` or
   `looker-dashboard-builder`).
2. Confirm, or default and state: platform; fiscal calendar (fiscal year start month);
   reporting currency and FX method (default: actuals at monthly average rate, budget at
   budget rate); entity scope; whether forecast exists.
3. Read `references/metrics.md` before writing any measure.

## Decisions this dashboard supports
- Are revenue, margin and EBITDA on plan for the month, quarter and year to date?
- Which line items, business units or cost centers drive the variance?
- Is the full-year forecast still achievable?
- Which cost centers are overspending and need a review with their owner?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_gl_actuals` | One row per GL journal line (or per account × cost center × entity × day, pre-aggregated) | posting_date, account_key, cost_center_key, entity_key, amount_local, amount_reporting, currency |
| `fact_budget` | Account × cost center × entity × month × scenario (Budget, Forecast v1…) | month, account_key, cost_center_key, scenario, amount_reporting |
| `dim_account` | GL account with P&L hierarchy | account_key, account_number, account_name, pl_line (Revenue, COGS, OpEx…), pl_line_order, sign_multiplier, account_type |
| `dim_cost_center` | Cost center / department | cost_center_key, name, department, owner, business_unit |
| `dim_entity` | Legal entity / company code | entity_key, name, region, functional_currency |
| `dim_date` | Day with fiscal attributes | date, fiscal_year, fiscal_quarter, fiscal_period, period_end_flag |
| `dim_scenario` (optional) | Actual / Budget / Forecast versions | scenario_key, scenario_name, is_current_forecast |

Mapping guidance: the P&L structure lives in `dim_account` (`pl_line` and a numeric
`pl_line_order`). If the customer has a separate financial statement hierarchy (FSG / FS
version), use it instead and keep its order. Never infer P&L lines from account-number ranges
without confirming with the user.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Typical tier |
|---|---|---|
| Revenue | Yes | L1 |
| Gross Margin, Gross Margin % | Yes | L1 |
| Operating Expenses (OpEx) | No | L1 |
| EBITDA, EBITDA Margin % | Yes | L1 |
| Net Income | Yes | L1 |
| Variance vs Budget (abs, %) | Depends on line | L1/L2 |
| Variance vs Forecast, vs PY | Depends on line | L2 |
| Full-year Forecast / Outlook | – | L1 |
| OpEx % of Revenue | No | L2 |
| Budget Consumption % (YTD actual ÷ annual budget) | Context | L2 |

## Pages

**Page 1 — Financial Performance Overview (L1)**
```
Header: "Financial Performance" · fiscal period · reporting currency · entity scope · last close date
Row 1: KPI cards (2 cols each): Revenue | Gross Margin % | OpEx | EBITDA | EBITDA Margin % | Net Income
       each with "vs Budget" delta (abs and %) and 13-period sparkline; period toggle MTD/QTD/YTD
Row 2: Trend (8 cols): Revenue and EBITDA actual vs budget by fiscal period, 13 periods
       Full-year outlook (4 cols): bullet chart — YTD actual + remaining forecast vs annual budget
Row 3: Waterfall (6 cols): Budget EBITDA → driver P&L lines → Actual EBITDA (YTD)
       Variance by business unit (6 cols): diverging bar of EBITDA variance vs budget
```

**Page 2 — P&L Statement (L2)**
- Matrix: rows = P&L hierarchy (pl_line → account group → account), columns = Actual |
  Budget | Var | Var % | PY | Var PY %, for MTD and YTD (toggle). Subtotals for Gross
  Margin, EBITDA, Operating Income, Net Income computed as measures, not as summed rows.
- Conditional formatting on Var % only, direction-aware per line (revenue up = good, cost up =
  bad).

**Page 3 — Cost Center Spend (L2)**
- Bullet chart per department: YTD actual vs YTD budget with annual budget marker.
- Ranked bar: top 10 cost centers by unfavorable variance.
- Trend: OpEx by category (people, travel, software, facilities, other) by month.
- Table: cost center | owner | YTD actual | YTD budget | var | consumption %.

**Page 4 — Account Detail (L3, drill-through from any account or cost center)**
- Table of journal lines: posting date, journal id, account, cost center, vendor/description,
  amount, source system; filters for period and amount threshold.

## Drill paths and filters
- Drill path: P&L line → account group → account → journal line (drill-through).
- Organization path: Entity → Business Unit → Department → Cost Center.
- Global filters: fiscal period (default: last closed period), entity, business unit,
  scenario for comparison (Budget / latest Forecast).

## Domain rules and gotchas
- **Sign convention.** GL stores revenue as credits (negative) and expenses as debits
  (positive). Apply `sign_multiplier` from `dim_account` (−1 for revenue/income lines) so the
  P&L reads naturally. Variance favorability = (Actual − Budget) × direction, where direction is
  +1 for revenue/income lines and −1 for cost lines.
- **Subtotals are measures.** Gross Margin = Revenue − COGS; EBITDA = Gross Margin − OpEx
  (excluding D&A); compute them, don't sum displayed rows.
- **Closed periods only.** Default to the last closed period; flag the current open period
  as "preliminary" if shown at all.
- **Budget grain.** Budgets rarely exist at account × day. Compare at month (or the budget's
  grain) and blank budget at finer levels instead of allocating silently.
- **FX.** Use the reporting-currency amount from the source or a monthly rate table; show the
  currency in the header. Never sum local-currency amounts across entities.
- **Intercompany.** Exclude intercompany accounts / eliminations entity for consolidated views
  unless the user asks for pre-elimination numbers.
- **Percent metrics at total level** are recomputed (EBITDA ÷ Revenue), never averaged.

## Platform notes
- **Power BI:** use a disconnected "P&L Layout" table (line, order, measure selector) with a
  SWITCH measure for the statement matrix so computed subtotal lines sit in the right order;
  time intelligence with fiscal year-end argument in `TOTALYTD`.
- **Tableau:** model actuals and budget as two related logical tables on account, cost
  center and month; build the statement as a text table with a P&L line sort calc.
- **Looker:** one explore with actuals as base and budget joined via a derived table at month ×
  account × cost center grain, or use a `UNION ALL` derived table with a scenario column — this
  avoids fanout and is usually the cleanest.

## Done when
- [ ] P&L totals for the last closed period tie to the trial balance / finance-provided
      numbers (state the reconciliation figure and source).
- [ ] Revenue displays positive and favorability colors are correct for cost lines.
- [ ] Budget comparisons blank (not zero) where budget doesn't exist.
- [ ] `bi-dashboard-design` acceptance checklist passes.
