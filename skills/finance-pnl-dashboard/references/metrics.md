# P&L Metric Definitions

All amounts in reporting currency after `sign_multiplier` (revenue positive, costs positive
as costs). "Period" means the fiscal period(s) in the filter context.

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Revenue | Net sales after returns, discounts and rebates | Σ amount × sign where pl_line = Revenue | Additive | Yes | $ abbreviated |
| COGS | Direct costs of goods/services sold | Σ amount where pl_line = COGS | Additive | No | $ |
| Gross Margin | Revenue − COGS | Revenue − COGS | Additive | Yes | $ |
| Gross Margin % | Gross margin as share of revenue | Gross Margin ÷ Revenue | Ratio – recompute | Yes | 0.0% |
| OpEx | Operating expenses excluding D&A | Σ amount where pl_line in (S&M, R&D, G&A, Other OpEx) | Additive | No | $ |
| EBITDA | Earnings before interest, tax, depreciation and amortization | Gross Margin − OpEx | Additive | Yes | $ |
| EBITDA Margin % | | EBITDA ÷ Revenue | Ratio | Yes | 0.0% |
| D&A | Depreciation and amortization | Σ amount where pl_line = D&A | Additive | No | $ |
| Operating Income (EBIT) | | EBITDA − D&A | Additive | Yes | $ |
| Net Income | Bottom line after interest and tax | Operating Income − Interest − Tax ± Other | Additive | Yes | $ |
| Budget | Approved annual budget phased by month | Σ fact_budget where scenario = Budget | Additive (month+) | – | $ |
| Forecast | Latest forecast version | Σ fact_budget where scenario is_current_forecast | Additive | – | $ |
| Var vs Budget | Actual − Budget | Actual − Budget | Additive | Favorable = (Actual − Budget) × direction > 0 | +$ |
| Var vs Budget % | | (Actual − Budget) ÷ ABS(Budget) | Ratio | as above | +0.0% |
| Var vs PY % | | (Actual − PY) ÷ ABS(PY) | Ratio | as above | +0.0% |
| Full-Year Outlook | YTD actual + forecast for remaining periods | Σ actual(closed periods) + Σ forecast(open periods) | Additive | depends on line | $ |
| Budget Consumption % | YTD actual ÷ full-year budget | Actual YTD ÷ Budget FY | Ratio | Context (vs % of year elapsed) | 0% |
| OpEx % of Revenue | | OpEx ÷ Revenue | Ratio | No | 0.0% |

Direction per P&L line: +1 for Revenue, Other Income, all margin/profit subtotals; −1 for
COGS, OpEx, D&A, Interest, Tax.

## Edge cases
- Budget is zero or missing → Var % is blank, not ±∞.
- Negative revenue months (large credit notes) → show, but flag in a tooltip.
- Reclassifications between periods change history; note the as-of date of the actuals.
- Partial current period → exclude from YTD unless the user asks for "flash" numbers.

## Implementations

### Revenue (sign-corrected)
**DAX**
```dax
Revenue =
CALCULATE (
    SUMX ( 'GL Actuals', 'GL Actuals'[AmountReporting] * RELATED ( Account[SignMultiplier] ) ),
    Account[PL Line] = "Revenue"
)
```
**Tableau**
```
// Revenue (sign-corrected)
SUM(IF [PL Line] = "Revenue" THEN [Amount Reporting] * [Sign Multiplier] END)
```
**LookML** (in the actuals view, with `dim_account` joined)
```lookml
measure: revenue {
  type: sum
  sql: ${amount_reporting} * ${dim_account.sign_multiplier} ;;
  filters: [dim_account.pl_line: "Revenue"]
  value_format_name: usd_0
}
```

### EBITDA and EBITDA Margin %
**DAX**
```dax
EBITDA = [Gross Margin] - [OpEx]
EBITDA Margin % = DIVIDE ( [EBITDA], [Revenue] )
```
**Tableau**
```
[Gross Margin] - [OpEx]
// EBITDA Margin %
[EBITDA] / [Revenue]
```
**LookML**
```lookml
measure: ebitda { type: number sql: ${gross_margin} - ${opex} ;; value_format_name: usd_0 }
measure: ebitda_margin_pct { type: number sql: 1.0 * ${ebitda} / NULLIF(${revenue}, 0) ;; value_format_name: percent_1 }
```

### Variance vs Budget with favorability
**DAX**
```dax
Var vs Budget = [Actual] - [Budget]
Var vs Budget Fav =
VAR dir = SELECTEDVALUE ( Account[Direction], 1 )
RETURN ( [Actual] - [Budget] ) * dir      -- > 0 favorable
Var vs Budget % = DIVIDE ( [Actual] - [Budget], ABS ( [Budget] ) )
```
**Tableau**
```
// Var vs Budget % (favorability via [Direction] on the color shelf)
(SUM([Actual]) - SUM([Budget])) / ABS(SUM([Budget]))
```
**LookML**
```lookml
measure: var_vs_budget_pct {
  type: number
  sql: 1.0 * (${actual} - ${budget}) / NULLIF(ABS(${budget}), 0) ;;
  value_format_name: percent_1
}
```

### Revenue YTD (fiscal) and prior year
**DAX** (fiscal year ending 31 March)
```dax
Revenue YTD = TOTALYTD ( [Revenue], 'Date'[Date], "03-31" )
Revenue PY = CALCULATE ( [Revenue], SAMEPERIODLASTYEAR ( 'Date'[Date] ) )
```
**Tableau**
```
// Revenue fiscal YTD (fiscal year start set on the date field's properties)
SUM(IF [Fiscal Year] = [Selected Fiscal Year] AND [Fiscal Period] <= [Selected Fiscal Period] THEN [Revenue Amount] END)
```
**LookML**
```lookml
measure: revenue_prior_year {
  type: period_over_period
  based_on: revenue
  based_on_time: posting_fiscal_month   # dimension_group with fiscal timeframes; set fiscal_month_offset in the model
  period: fiscal_year
  kind: previous
}
```
Check that the connection's dialect and the Looker version support `period_over_period`
with fiscal periods; if not, use filtered measures on `posting_fiscal_year` /
`posting_fiscal_quarter` (see `looker-dashboard-builder/references/lookml-patterns.md`).
