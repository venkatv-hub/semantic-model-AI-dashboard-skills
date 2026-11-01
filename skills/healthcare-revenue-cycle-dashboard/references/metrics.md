# Revenue Cycle Metric Definitions

Definitions follow common industry practice; customers often have their own variants
(e.g. HFMA MAP Keys). Always confirm and record the customer's definition in the spec.

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Gross Charges | Charges posted in period | Σ gross_charge by post_date | Additive | Context | $ |
| Net Collections | Payments from payers and patients in period | Σ payments | Additive | Yes | $ |
| Contractual Adjustments | Write-downs to contracted rates | Σ contractual_adjustment | Additive | – | $ |
| Net Collection Rate % | Share of collectible amount actually collected | Payments ÷ (Charges − Contractual Adjustments), on the same cohort of encounters/claims | Ratio | Yes (target ≥ 95%) | 0.0% |
| Gross A/R | Total outstanding patient account balances | Σ ar_balance at snapshot (debit balances) | Semi-additive | Context | $ |
| Average Daily Gross Charges | | Σ gross charges last 90 days ÷ 90 | Non-additive | – | $ |
| Days in A/R | | Gross A/R ÷ Average Daily Gross Charges | Non-additive | No | 0.0 d |
| A/R > 90 Days % | | A/R where days_since_discharge > 90 ÷ Gross A/R | Ratio | No | 0.0% |
| Clean Claim Rate % | Claims accepted without edits/rejections on first submission | count(is_clean_claim AND submission_number = 1) ÷ count(submission_number = 1) | Ratio | Yes | 0.0% |
| Initial Denial Rate % | Initial claims denied (full or line-level) at first adjudication | count(denied initial claims) ÷ count(adjudicated initial claims) | Ratio | No | 0.0% |
| Denied Dollars | | Σ billed amount of denied claims/lines | Additive | No | $ |
| Preventable Denial % | | denied claims with is_preventable reason ÷ denied claims | Ratio | No | 0.0% |
| Denial Overturn Rate % | Denied claims later paid after appeal/resubmission | count(overturned) ÷ count(appealed) | Ratio | Yes | 0.0% |
| First-Pass Resolution % | Claims paid in full on first submission | count(paid, no denial, submission 1) ÷ count(adjudicated initial claims) | Ratio | Yes | 0.0% |
| POS Collection Rate % | Patient responsibility collected at or before service | Σ POS patient payments ÷ Σ patient responsibility due at service | Ratio | Yes | 0.0% |
| Bad Debt % | | Bad debt write-offs ÷ gross patient service revenue | Ratio | No | 0.00% |
| Cost to Collect % | RCM operating cost ÷ net collections | Σ rcm_cost ÷ Net Collections | Ratio | No | 0.00% |

## Edge cases
- Claims with partial line-level denials: count as denied for initial denial rate when any
  line is denied (or follow the customer's line-level definition and say so).
- Zero-pay but "approved" remits (paid to deductible) are not denials; check group code PR.
- Credit balances excluded from Gross A/R; show "Credit Balances" separately.
- Small cells: suppress values when distinct encounters < 11 on shared dashboards.

## Implementations

### Initial Denial Rate %
**DAX**
```dax
Initial Claims Adjudicated =
CALCULATE ( DISTINCTCOUNT ( Remits[ClaimId] ), Claims[SubmissionNumber] = 1 )
Initial Claims Denied =
CALCULATE ( DISTINCTCOUNT ( Remits[ClaimId] ), Claims[SubmissionNumber] = 1, Remits[DenialFlag] = TRUE () )
Initial Denial Rate % = DIVIDE ( [Initial Claims Denied], [Initial Claims Adjudicated] )
```
(Claims filters Remits through `ClaimId`; if both are facts, relate Remits → Claims as
many-to-one on ClaimId.)
**Tableau**
```
// Initial Denial Rate %
COUNTD(IF [Submission Number] = 1 AND [Denial Flag] THEN [Claim Id] END)
/ COUNTD(IF [Submission Number] = 1 THEN [Claim Id] END)
```
**LookML**
```lookml
measure: initial_claims_adjudicated { type: count_distinct sql: ${claim_id} ;; filters: [claims.submission_number: "1"] }
measure: initial_claims_denied { type: count_distinct sql: ${claim_id} ;; filters: [claims.submission_number: "1", denial_flag: "yes"] }
measure: initial_denial_rate { type: number sql: 1.0 * ${initial_claims_denied} / NULLIF(${initial_claims_adjudicated}, 0) ;; value_format_name: percent_1 }
```

### Days in A/R
**DAX**
```dax
Gross AR =
CALCULATE (
    SUM ( 'AR Snapshot'[ARBalance] ),
    'AR Snapshot'[ARBalance] > 0,
    LASTNONBLANK ( 'Date'[Date], CALCULATE ( COUNTROWS ( 'AR Snapshot' ) ) )
)
Avg Daily Gross Charges 90D =
VAR EndDate = MAX ( 'Date'[Date] )
RETURN DIVIDE ( CALCULATE ( [Gross Charges], DATESINPERIOD ( 'Date'[Date], EndDate, -90, DAY ) ), 90 )
Days in AR = DIVIDE ( [Gross AR], [Avg Daily Gross Charges 90D] )
```
**Tableau / LookML** – precompute `charges_90d` per day in the warehouse (rolling sum) and
divide period-end Gross A/R by `charges_90d / 90`; same pattern as standard DSO in
`finance-ar-collections-dashboard`.

### Net Collection Rate %
**DAX**
```dax
Net Collection Rate % =
DIVIDE ( [Payments on Cohort], [Charges on Cohort] - [Contractual Adjustments on Cohort] )
```
"Cohort" = encounters with service dates in a closed window (e.g. services 3–6 months ago),
so slow payments have time to arrive. Build cohort measures with the service-date
relationship (`USERELATIONSHIP` if not active).
**Tableau**
```
SUM([Cohort Payments]) / (SUM([Cohort Charges]) - SUM([Cohort Contractual Adj]))
```
**LookML**
```lookml
measure: net_collection_rate {
  type: number
  sql: 1.0 * ${cohort_payments} / NULLIF(${cohort_charges} - ${cohort_contractual_adj}, 0) ;;
  value_format_name: percent_1
}
```

### Small-cell suppression (display)
**DAX**
```dax
Denial Rate (suppressed) = IF ( [Distinct Encounters] < 11, BLANK (), [Initial Denial Rate %] )
```
**Tableau**
```
IF COUNTD([Encounter Key]) < 11 THEN NULL ELSE [Initial Denial Rate %] END
```
**LookML**
```lookml
measure: denial_rate_suppressed {
  type: number
  sql: CASE WHEN ${distinct_encounters} < 11 THEN NULL ELSE ${initial_denial_rate} END ;;
  value_format_name: percent_1
}
```
