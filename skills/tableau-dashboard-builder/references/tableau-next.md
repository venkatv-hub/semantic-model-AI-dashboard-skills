# Tableau Next Notes

Tableau Next runs on the Salesforce platform with Data Cloud. Its semantic layer (the
Semantic Data Model, SDM) is the equivalent of a published data source, and dashboards are
built on top of it.

## Mapping the spec to Tableau Next

| Spec concept | Tableau Next object |
|---|---|
| Fact / dimension tables | Data objects (DLOs/DMOs) added to the semantic model |
| Relationships | Semantic model relationships between data objects |
| Base measures | Semantic measurements on the data object |
| Ratios / derived measures | Calculated measurements |
| Bucket / derived dimensions | Calculated dimensions |
| KPIs with time grain and targets | Semantic metrics (time dimension, aggregation, optional goals) |
| Dashboard components | Dashboard widgets (metric, visualization, filter, text); custom LWC widgets for components the native set lacks |

## Workflow
1. Check what exists: list semantic models and their data objects, dimensions, measurements
   and metrics (the Tableau Next hosted MCP server exposes these tools when connected).
2. Reuse existing measurements where the definition matches the domain metrics file; add
   calculated measurements only where missing, with descriptions.
3. Define metrics for every L1 KPI (time dimension = the domain's primary date, plus
   additional dimensions used for breakdowns) so they can power metric widgets and Agentforce.
4. Build the dashboard following the same L1/L2/L3 structure; use metric widgets for KPI
   cards and visualizations for trends and breakdowns.
5. Deploy metadata through the Salesforce CLI or the user's DevOps process; do not edit
   production org metadata directly without the user's approval.

## Calculation syntax
Calculated fields in Tableau Next use Tableau-style expressions; aggregation and LOD support
differs from Tableau Desktop. Verify each calc in the semantic model editor and keep a
Tableau Desktop version from `calc-patterns.md` for comparison.
