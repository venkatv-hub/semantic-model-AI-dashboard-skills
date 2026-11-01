# Hospital Operations Metric Definitions

| Metric | Definition | Formula | Additivity | Higher is better | Format |
|---|---|---|---|---|---|
| Midnight Census | Inpatients in a bed at midnight | occupied_beds at census_date (latest) | Snapshot | Context | # |
| Patient Days | | Σ daily midnight census over period | Additive | Context | # |
| Bed Days Available | | Σ staffed_beds over days | Additive | – | # |
| Bed Occupancy % | | Patient Days ÷ Bed Days Available | Ratio | Target band | 0.0% |
| Discharges | Inpatient discharges in period | count(encounter_type = inpatient, discharge in period) | Additive | Context | # |
| ALOS | Average length of stay | Σ LOS days ÷ Discharges (LOS = discharge_date − admit_date, min 1) | Ratio | No | 0.0 d |
| Expected LOS | DRG geometric mean LOS (or customer's expected) | Σ expected_los ÷ Discharges | Ratio | – | 0.0 d |
| LOS Index | Observed vs expected | Σ LOS ÷ Σ expected_los | Ratio | No (< 1.0 good) | 0.00 |
| Excess Days | | Σ (LOS − expected_los) | Additive | No | # |
| Discharges Before Noon % | | count(discharge_time < 12:00) ÷ Discharges | Ratio | Yes | 0.0% |
| 30-day Readmission Rate % | Unplanned readmissions within 30 days of eligible index discharges | count(index with unplanned readmit ≤ 30 d) ÷ count(eligible index discharges) | Ratio | No | 0.0% |
| Door-to-Provider | ED arrival to first provider contact | median(provider_seen − arrival) minutes | Non-additive | No | 0 min |
| LWBS % | Left without being seen | count(disposition = LWBS) ÷ count(ED visits) | Ratio | No | 0.0% |
| ED Boarding Time | Decision-to-admit to ED departure | median(departure − decision_to_admit) hours, admitted only | Non-additive | No | 0.0 h |
| ED Length of Stay | Arrival to departure | median(departure − arrival), by disposition | Non-additive | No | 0.0 h |
| OR Utilization % | In-room minutes ÷ available block minutes | Σ (out_room − in_room) ÷ Σ available minutes | Ratio | Yes | 0.0% |
| First-Case On-time Start % | First cases in room by scheduled start (+ grace, default 5 min) | count(is_first_case AND in_room ≤ scheduled + 5) ÷ count(first cases) | Ratio | Yes | 0.0% |
| Case Mix Index | Average DRG relative weight | Σ drg_weight ÷ Discharges | Ratio | Context | 0.00 |

Eligible index discharge: inpatient, discharged alive, not transferred to another acute
facility, not left against medical advice (confirm the customer's rule), discharge date at
least 30 days before the data cut-off.

## Implementations

### Bed Occupancy %
**DAX**
```dax
Patient Days = SUM ( Census[OccupiedBeds] )
Bed Days Available = SUM ( Census[StaffedBeds] )
Bed Occupancy % = DIVIDE ( [Patient Days], [Bed Days Available] )
```
**Tableau**
```
SUM([Occupied Beds]) / SUM([Staffed Beds])
```
**LookML**
```lookml
measure: patient_days { type: sum sql: ${TABLE}.OCCUPIED_BEDS ;; }
measure: bed_days_available { type: sum sql: ${TABLE}.STAFFED_BEDS ;; }
measure: bed_occupancy_pct { type: number sql: 1.0 * ${patient_days} / NULLIF(${bed_days_available}, 0) ;; value_format_name: percent_1 }
```

### ALOS and LOS Index
**DAX**
```dax
Inpatient Discharges = CALCULATE ( COUNTROWS ( Encounters ), Encounters[EncounterType] = "Inpatient" )
LOS Days =
CALCULATE (
    SUMX ( Encounters, MAX ( 1, INT ( Encounters[DischargeDate] - Encounters[AdmitDate] ) ) ),
    Encounters[EncounterType] = "Inpatient"
)
ALOS = DIVIDE ( [LOS Days], [Inpatient Discharges] )
LOS Index = DIVIDE ( [LOS Days], CALCULATE ( SUM ( Encounters[ExpectedLOS] ), Encounters[EncounterType] = "Inpatient" ) )
```
**Tableau**
```
// ALOS
SUM(IF [Encounter Type] = "Inpatient" THEN MAX(1, DATEDIFF('day', [Admit Date], [Discharge Date])) END)
/ SUM(IF [Encounter Type] = "Inpatient" THEN 1 END)
```
**LookML**
```lookml
dimension: los_days { type: number sql: GREATEST(1, DATEDIFF(day, ${TABLE}.ADMIT_DATE, ${TABLE}.DISCHARGE_DATE)) ;; }
measure: inpatient_discharges { type: count filters: [encounter_type: "Inpatient"] }
measure: total_los_days { type: sum sql: ${los_days} ;; filters: [encounter_type: "Inpatient"] }
measure: alos { type: number sql: 1.0 * ${total_los_days} / NULLIF(${inpatient_discharges}, 0) ;; value_format_name: decimal_1 }
```

### 30-day Readmission Rate
**DAX**
```dax
Eligible Index Discharges = CALCULATE ( COUNTROWS ( Readmissions ), Readmissions[IsEligibleIndex] = TRUE () )
Readmitted 30D =
CALCULATE (
    COUNTROWS ( Readmissions ),
    Readmissions[IsEligibleIndex] = TRUE (),
    Readmissions[IsUnplanned] = TRUE (),
    Readmissions[DaysToReadmit] <= 30
)
Readmission Rate % = IF ( [Eligible Index Discharges] < 11, BLANK (), DIVIDE ( [Readmitted 30D], [Eligible Index Discharges] ) )
```
**Tableau**
```
IF SUM(INT([Is Eligible Index])) < 11 THEN NULL
ELSE SUM(INT([Is Eligible Index] AND [Is Unplanned] AND [Days To Readmit] <= 30)) / SUM(INT([Is Eligible Index]))
END
```
**LookML**
```lookml
measure: eligible_index { type: count filters: [is_eligible_index: "yes"] }
measure: readmitted_30d { type: count filters: [is_eligible_index: "yes", is_unplanned: "yes", days_to_readmit: "<=30"] }
measure: readmission_rate {
  type: number
  sql: CASE WHEN ${eligible_index} < 11 THEN NULL ELSE 1.0 * ${readmitted_30d} / ${eligible_index} END ;;
  value_format_name: percent_1
}
```

### ED Door-to-Provider (median minutes)
**DAX**
```dax
Door to Provider (min) =
MEDIANX ( FILTER ( 'ED Visits', NOT ISBLANK ( 'ED Visits'[ProviderSeenDateTime] ) ),
          DATEDIFF ( 'ED Visits'[ArrivalDateTime], 'ED Visits'[ProviderSeenDateTime], MINUTE ) )
```
**Tableau**
```
MEDIAN(DATEDIFF('minute', [Arrival Datetime], [Provider Seen Datetime]))
```
**LookML**
```lookml
dimension_group: door_to_provider {
  type: duration
  intervals: [minute]
  sql_start: ${TABLE}.ARRIVAL_DATETIME ;;
  sql_end: ${TABLE}.PROVIDER_SEEN_DATETIME ;;
}
measure: door_to_provider_median { type: median sql: ${minutes_door_to_provider} ;; value_format_name: decimal_0 }
```
