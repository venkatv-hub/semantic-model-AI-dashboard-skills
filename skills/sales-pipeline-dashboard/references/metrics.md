# Sales Pipeline Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Bookings | Closed-won amount by close date | Σ amount where is_won | Additive | Yes | $ |
| Quota | Assigned quota for the period | Σ quota_amount | Additive (same period grain) | – | $ |
| Quota Attainment % | | Bookings ÷ Quota | Ratio | Yes | 0.0% |
| Open Pipeline | Open opportunities with expected close date in window | Σ amount where not is_closed | Snapshot (current) | Yes | $ |
| Weighted Pipeline | | Σ amount × probability (open) | Snapshot | Context | $ |
| Commit Forecast | Bookings to date + open Commit | Bookings + Σ amount(open, forecast_category = Commit) | – | Context | $ |
| Pipeline Coverage | Open pipeline for remaining period ÷ remaining quota | Open Pipeline(remaining) ÷ max(Quota − Bookings, 0) | Ratio | Yes (≈ 3x) | 0.0x |
| Win Rate % | Won ÷ closed (won + lost), closed in window | count(won) ÷ count(won + lost) | Ratio | Yes | 0.0% |
| Average Deal Size | | Bookings ÷ count(won) | Ratio | Yes | $ |
| Sales Cycle | Created to close for won deals | avg(close_date − created_date) for won | Non-additive | No | 0 d |
| Stage Conversion % | Opportunities that reached stage N+1 ÷ reached stage N (cohort) | count(reached N+1) ÷ count(reached N) | Ratio | Yes | 0.0% |
| Pipeline Velocity | Revenue throughput per day | (# open opps × win rate × avg deal size) ÷ sales cycle days | Non-additive | Yes | $/day |
| Pipeline Created | New opportunity amount by created date | Σ amount by created_date | Additive | Yes | $ |
| Slipped Deals | Open deals whose close date moved out of the period since the period-start snapshot | count / Σ amount | Additive | No | # / $ |
| Forecast Accuracy % | 1 − abs error of week-N commit forecast vs actual bookings | 1 − ABS(Actual − Forecast) ÷ Actual | Ratio | Yes | 0.0% |

## Implementations

### Win Rate %
**DAX**
```dax
Won Deals = CALCULATE ( COUNTROWS ( Opportunities ), Opportunities[IsWon] = TRUE () )
Lost Deals = CALCULATE ( COUNTROWS ( Opportunities ), Opportunities[IsClosed] = TRUE (), Opportunities[IsWon] = FALSE (), Opportunities[LossReason] <> "Duplicate" )
Win Rate % = DIVIDE ( [Won Deals], [Won Deals] + [Lost Deals] )
```
**Tableau**
```
SUM(INT([Is Won])) / SUM(INT([Is Closed] AND [Loss Reason] != "Duplicate"))
```
(Use a separate exclusion flag field if loss reasons vary.)
**LookML**
```lookml
measure: won_deals { type: count filters: [is_won: "yes"] }
measure: closed_deals { type: count filters: [is_closed: "yes", loss_reason: "-Duplicate"] }
measure: win_rate { type: number sql: 1.0 * ${won_deals} / NULLIF(${closed_deals}, 0) ;; value_format_name: percent_1 }
```

### Pipeline Coverage (rest of quarter)
**DAX** (Date table filtered to the current fiscal quarter)
```dax
Remaining Quota = MAX ( [Quota] - [Bookings], 0 )
Open Pipeline Remaining =
VAR AsOfDate = TODAY ()
VAR QEnd = MAX ( 'Date'[Date] )
RETURN
CALCULATE (
    SUM ( Opportunities[Amount] ),
    Opportunities[IsClosed] = FALSE (),
    DATESBETWEEN ( 'Date'[Date], AsOfDate, QEnd )
)
Pipeline Coverage = DIVIDE ( [Open Pipeline Remaining], [Remaining Quota] )
```
**Tableau**
```
SUM(IF NOT [Is Closed] AND [Close Date] >= TODAY() AND [Close Date] <= [Quarter End] THEN [Amount] END)
/ MAX(SUM([Quota]) - SUM(IF [Is Won] THEN [Amount] END), 0)
```
Quota comes from a related quota table; check the relationship is at owner × quarter.
**LookML**
```lookml
measure: open_pipeline_remaining {
  type: sum
  sql: ${amount} ;;
  filters: [is_closed: "no", close_date: "today for 1 quarter"]
}
measure: pipeline_coverage {
  type: number
  sql: ${open_pipeline_remaining} / NULLIF(GREATEST(${quota.total_quota} - ${bookings}, 0), 0) ;;
  value_format: "0.0\"x\""
}
```
(Adjust the relative filter to the fiscal quarter end; Looker's `this fiscal quarter`
works when `fiscal_month_offset` is set.)

### Bookings cumulative vs quota (trend)
**DAX**
```dax
Bookings QTD Cumulative =
CALCULATE ( [Bookings], DATESQTD ( 'Date'[Date] ) )
```
(Use a fiscal-quarter calendar column with a running total if the fiscal quarters are not
calendar-aligned: `CALCULATE([Bookings], FILTER(ALL('Date'), 'Date'[Fiscal Quarter] = MAX('Date'[Fiscal Quarter]) && 'Date'[Date] <= MAX('Date'[Date])))`.)
**Tableau**
```
RUNNING_SUM(SUM(IF [Is Won] THEN [Amount] END))   // compute along fiscal week within quarter
```
**LookML** – use a `running_total` table calculation in the dashboard element
(`dynamic_fields`) on a week-of-quarter dimension; this is presentational so it can live in
the dashboard.
