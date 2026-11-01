---
name: domain-area-dashboard
description: Designs and builds a <DOMAIN AREA> dashboard — <5–10 headline metrics> — in Power BI, Tableau or Looker. Use this skill whenever the user asks for a <domain keywords, synonyms and common phrasings> dashboard, report or semantic model, even if they only say "<a casual phrasing a business user would use>".
---

<!--
  How to use this template
  1. Copy this folder to skills/<domain>-<area>-dashboard/ (lowercase, hyphens).
  2. Set `name` to exactly the folder name.
  3. Write the description in third person: what it builds + when to use it, with the
     words real users type. Keep it under 1024 characters.
  4. Fill every section below; delete these comments.
  5. Put every metric definition in references/metrics.md.
  6. Run `python3 scripts/skills.py validate` and `python3 scripts/skills.py catalog`.
-->

# <Domain> — <Area> Dashboard

<One paragraph: who uses it and the outcome it protects.>

## Before you start
1. Read `bi-dashboard-design` and the platform builder skill.
2. Confirm or default: platform; <definition choices that change the numbers, each with a
   stated default>.
3. Read `references/metrics.md`.

## Decisions this dashboard supports
- <Decision 1>
- <Decision 2>
- <Decision 3>

## Canonical data model

| Table | Grain | Key columns |
|---|---|---|
| `fact_<name>` | <one row per …> | <columns> |
| `dim_<name>` | <…> | <columns> |

<Mapping guidance: what to do when the customer's data differs.>

## Metrics (definitions in `references/metrics.md`)

| Metric | Higher is better | Tier |
|---|---|---|
| <Metric> | Yes / No / Context / Target band | L1 / L2 |

## Pages

**Page 1 — <Name> Overview (L1)**
```
Header: "<Title>" · <period> · <unit/currency> · <scope>
Row 1: KPIs: <KPI 1> | <KPI 2> | <KPI 3> | <KPI 4> | <KPI 5> | <KPI 6>
Row 2: <trend> (8 cols) | <breakdown> (4 cols)
Row 3: <variance / ranked> (6 cols) | <exceptions> (6 cols)
```

**Page 2 — <Analysis> (L2)**
- <components>

**Page 3 — <Detail> (L3, drill-through)**
- <exception or record table, with link to the source system>

## Drill paths and filters
- <Hierarchy 1>
- Filters: <period default>, <org>, <domain dimension>.

## Domain rules and gotchas
- <Additivity: which measures are snapshots>
- <Definition traps that change the number>
- <Data-quality issues to surface>
- <Privacy / compliance rules if relevant>

## Platform notes
- **Power BI:** <specific tips>
- **Tableau:** <specific tips>
- **Looker:** <specific tips>

## Done when
- [ ] <Reconciliation to a trusted source>
- [ ] <Domain sanity check>
- [ ] `bi-dashboard-design` acceptance checklist passes.
