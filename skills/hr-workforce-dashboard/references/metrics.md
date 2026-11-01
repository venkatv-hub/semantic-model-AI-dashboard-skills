# HR Workforce Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Headcount | Active employees at period end (excl. contractors, interns) | count(distinct employee) at last snapshot where status = Active | Semi-additive | Context | #,0 |
| FTE | | Σ fte at last snapshot | Semi-additive | Context | #,0.0 |
| Average Headcount | Mean of month-end headcounts in the window | AVG over months(Headcount) | Non-additive | – | #,0 |
| Hires | Hire + rehire events in period | count(event_type in (hire, rehire)) | Additive | Context | # |
| Terminations | | count(event_type = termination) | Additive | Context | # |
| Attrition Rate % (R12M) | | Terminations (12 months) ÷ Average Headcount (12 months) | Ratio | No | 0.0% |
| Voluntary Attrition % | | Voluntary terminations ÷ Average Headcount | Ratio | No | 0.0% |
| Regretted Attrition % | | Regretted terminations ÷ Average Headcount | Ratio | No | 0.0% |
| Annualized Attrition (short window) | | (Terminations ÷ Average Headcount) × 12 ÷ months in window | Ratio | No | 0.0% |
| First-Year Attrition % | Leavers with tenure < 12 months ÷ hires in the prior 12 months | count(term with tenure < 12m) ÷ Hires(12m) | Ratio | No | 0.0% |
| Headcount vs Plan | | Headcount − Planned Headcount | Semi-additive | Context | +#,0 |
| Time to Fill | Requisition opened to offer accepted (filled) | median(filled_date − opened_date) for filled reqs | Non-additive | No | 0 d |
| Offer Acceptance Rate % | | offers accepted ÷ offers extended | Ratio | Yes | 0.0% |
| Internal Mobility Rate % | | (promotions + lateral transfers) ÷ Average Headcount | Ratio | Yes | 0.0% |
| Span of Control | Average direct reports per people manager | count(employees with a manager) ÷ count(distinct managers) at snapshot | Non-additive | Target band | 0.0 |
| Open Requisitions | | count(status = Open) at snapshot | Semi-additive | Context | # |

Suppression: return blank when the group's Average Headcount (or headcount) is below the
minimum group size (default 5).

## Implementations

### Headcount (period end)
**DAX**
```dax
Headcount =
CALCULATE (
    DISTINCTCOUNT ( 'Employee Snapshot'[EmployeeKey] ),
    'Employee Snapshot'[Status] = "Active",
    'Employee Snapshot'[EmploymentType] = "Employee",
    LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'Employee Snapshot' ) ) )
)
```
**Tableau**
```
COUNTD(IF [Is Period-End Snapshot] AND [Status] = "Active" AND [Employment Type] = "Employee" THEN [Employee Key] END)
```
**LookML**
```lookml
measure: headcount {
  type: count_distinct
  sql: ${employee_key} ;;
  filters: [is_period_end: "yes", status: "Active", employment_type: "Employee"]
}
```

### Attrition Rate % (rolling 12 months, with suppression)
**DAX**
```dax
Terminations R12M =
CALCULATE ( [Terminations], DATESINPERIOD ( 'Date'[Date], MAX ( 'Date'[Date] ), -12, MONTH ) )
Average Headcount R12M =
CALCULATE (
    AVERAGEX ( VALUES ( 'Date'[Month Start] ), CALCULATE ( [Headcount] ) ),
    DATESINPERIOD ( 'Date'[Date], MAX ( 'Date'[Date] ), -12, MONTH )
)
Attrition Rate % R12M =
IF ( [Average Headcount R12M] < 5, BLANK (), DIVIDE ( [Terminations R12M], [Average Headcount R12M] ) )
```
**Tableau** – compute on a monthly view, compute using month:
```
// Attrition R12M
IF WINDOW_AVG([Headcount], -11, 0) < 5 THEN NULL
ELSE WINDOW_SUM(SUM([Terminations]), -11, 0) / WINDOW_AVG([Headcount], -11, 0)
END
```
(The view must include the prior 11 months; hide them with a table-calc filter
`LAST() = 0` if only the latest month is displayed.)
**LookML** – monthly derived table:
```sql
SELECT month, org_unit_key, headcount, terminations,
       SUM(terminations) OVER (PARTITION BY org_unit_key ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS terms_r12m,
       AVG(headcount)    OVER (PARTITION BY org_unit_key ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS avg_hc_r12m
FROM hr_monthly_summary
```
```lookml
measure: attrition_r12m {
  type: number
  sql: CASE WHEN SUM(${TABLE}.avg_hc_r12m) < 5 THEN NULL
            ELSE SUM(${TABLE}.terms_r12m) / NULLIF(SUM(${TABLE}.avg_hc_r12m), 0) END ;;
  value_format_name: percent_1
}
```
Keep this explore filtered to a single month; summing `avg_hc_r12m` across org units for one
month gives the correct company-level average.

### Time to Fill (median)
**DAX**
```dax
Time to Fill (median days) =
MEDIANX ( FILTER ( Requisitions, NOT ISBLANK ( Requisitions[FilledDate] ) ), Requisitions[FilledDate] - Requisitions[OpenedDate] )
```
**Tableau**
```
MEDIAN(DATEDIFF('day', [Opened Date], [Filled Date]))
```
**LookML**
```lookml
dimension_group: open_to_fill { type: duration intervals: [day] sql_start: ${TABLE}.OPENED_DATE ;; sql_end: ${TABLE}.FILLED_DATE ;; }
measure: time_to_fill_median { type: median sql: ${days_open_to_fill} ;; value_format_name: decimal_0 }
```
