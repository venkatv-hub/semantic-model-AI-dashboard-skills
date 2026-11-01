---
name: healthcare-hospital-operations-dashboard
description: Designs and builds a hospital operations and patient flow dashboard — inpatient census, bed occupancy, average length of stay (ALOS) vs expected, 30-day readmission rate, discharges before noon, ED door-to-provider time, left without being seen (LWBS), ED boarding, OR utilization and case mix index — in Power BI, Tableau or Looker, with PHI-safe aggregation. Use this skill whenever the user asks for a hospital operations, patient flow, capacity, bed management, census, length of stay, readmissions, emergency department throughput, perioperative or clinical operations dashboard or semantic model.
---

# Healthcare — Hospital Operations and Patient Flow Dashboard

Gives hospital leadership and unit managers a shared view of capacity and throughput:
are beds available, are patients moving through the ED and inpatient units efficiently, and
are outcomes like readmissions moving in the right direction.

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; census time (default: midnight census); bed basis for
   occupancy (default: staffed beds; alternative: licensed beds); whether observation patients
   are included in census/LOS (default: excluded from inpatient LOS, shown separately);
   readmission definition (default: all-cause unplanned readmission to the same facility within
   30 days of an index discharge; regulatory programs use specific cohorts — confirm);
   expected LOS source (e.g. GMLOS by DRG) if variance to expected is needed; refresh frequency
   (operations views are often near-real-time or hourly).
3. Apply PHI rules (see `healthcare-revenue-cycle-dashboard` → PHI and compliance rules; same
   rules here). Read `references/metrics.md`.

## Decisions this dashboard supports
- Do we have capacity today and tomorrow (beds, ED boarding), and where are the bottlenecks?
- Is length of stay above expected for any unit or DRG, and are discharges happening early in
  the day?
- Is ED throughput meeting targets (door-to-provider, LWBS, boarding)?
- Are readmissions trending down, and for which service lines?

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_encounters` | Inpatient / observation / ED encounter | encounter_key, facility_key, unit_key, service_line_key, encounter_type, admit_datetime, discharge_datetime, drg_code, drg_weight, expected_los, discharge_disposition, is_planned_readmission_excluded |
| `fact_census_daily` | Unit × date (midnight census) | census_date, unit_key, occupied_beds, staffed_beds, licensed_beds, observation_patients |
| `fact_ed_visits` | ED visit | ed_visit_key, arrival_datetime, provider_seen_datetime, decision_to_admit_datetime, departure_datetime, disposition (admitted, discharged, LWBS, transferred), acuity (ESI) |
| `fact_or_cases` | Surgical case | case_key, room_key, scheduled_start, in_room_datetime, out_room_datetime, is_first_case, was_cancelled |
| `fact_readmissions` | Index discharge | index_encounter_key, readmit_encounter_key, days_to_readmit, is_unplanned |
| `dim_unit`, `dim_facility`, `dim_service_line`, `dim_drg`, `dim_or_room`, `dim_date`, `dim_hour` | | |

No patient identifiers are required; use surrogate encounter keys.

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| Midnight Census | Context | L1 |
| Bed Occupancy % | Target band (≈ 85%) | L1 |
| ALOS (days) and ALOS vs Expected (index) | No | L1 |
| 30-day Readmission Rate % | No | L1 |
| Discharges Before Noon % | Yes | L1 |
| ED Door-to-Provider (median min) | No | L1 |
| ED LWBS % | No | L2 |
| ED Boarding Time (median hrs) | No | L2 |
| OR Utilization %, First-Case On-time Start % | Yes | L2 |
| Case Mix Index | Context | L2 |

## Pages

**Page 1 — Hospital Operations Overview (L1)**
```
Header: "Hospital Operations" · facility · as-of (date/time) · "Aggregated – no PHI"
Row 1: KPIs: Census (vs same weekday avg) | Occupancy % (vs target band) | ALOS vs Expected | Readmission Rate % (rolling 12M) | Discharges Before Noon % | ED Door-to-Provider (median)
Row 2: Occupancy by unit, bullet vs target band (6 cols) | Census trend daily, last 30 days, with staffed beds line (6 cols)
Row 3: ALOS vs expected by service line, variance bar (6 cols) | ED throughput by hour-of-day: arrivals vs provider-seen median (6 cols)
```

**Page 2 — Patient Flow and Length of Stay (L2)**
- Discharge timing histogram by hour, by unit.
- Matrix: service line × month, ALOS / expected LOS index with heat.
- Table: DRGs with highest excess days (Σ(LOS − expected LOS)).

**Page 3 — Emergency Department (L2)**
- Trend by week: door-to-provider median, LWBS %, boarding median hours.
- Heat map: arrivals by day-of-week × hour (staffing view).
- Breakdown by acuity (ESI level).

**Page 4 — Perioperative (L2)**
- OR utilization by room and service; first-case on-time starts; turnover time median;
  cancellation rate.

**Page 5 — Readmissions (L2)**
- Trend of rolling 12-month readmission rate; by service line and discharge disposition;
  small-cell suppression applied. No patient-level L3 page by default; add only for
  authorized care-management roles.

## Drill paths and filters
- Facility → Unit → (bed type).
- Service line → DRG.
- Filters: facility, date range (operational pages default: last 30 days; outcome pages:
  last 12 months), unit, service line, encounter type, acuity.

## Domain rules and gotchas
- **Census is a snapshot** at a set time — don't sum census across days; patient days = Σ
  daily census (that sum is the meaningful additive quantity).
- **Occupancy** = patient days ÷ bed days available (staffed beds × days); show which bed
  basis.
- **ALOS** = Σ LOS days ÷ discharges for inpatients discharged in the period; exclude
  observation and same-day; outliers matter, so show median in tooltip.
- **Readmissions**: exclude planned readmissions and transfers; deaths at index stay are not
  eligible index discharges; the most recent 30 days of discharges are not yet complete —
  lag the rate.
- **Times** (door-to-provider, boarding) use medians; averages are skewed by extreme waits.
- **Small cells**: suppress rates when denominators < 11 on broadly shared pages.
- **Clinical outcomes** comparisons across units can be misleading without risk adjustment;
  label unadjusted rates clearly.

## Platform notes
- **Power BI:** use DirectQuery or frequent refresh for near-real-time census; time-of-day
  analysis needs a `dim_hour` table or hour column; medians with `MEDIANX`.
- **Tableau:** live connection or frequent extract refresh for census; MEDIAN on
  DATEDIFF('minute', …) for ED times; heat map with day-of-week × hour.
- **Looker:** `dimension_group: type: duration` for LOS and ED intervals; `datagroup` with
  a short max_cache_age for operational pages.

## Done when
- [ ] Patient days and discharges reconcile to the hospital's census/ADT reports.
- [ ] Observation handling and bed basis are stated on the page.
- [ ] Readmission rate excludes planned readmissions and the incomplete latest 30 days.
- [ ] No PHI in the model; small cells suppressed.
- [ ] `bi-dashboard-design` acceptance checklist passes.
