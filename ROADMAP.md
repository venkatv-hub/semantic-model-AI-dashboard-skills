# Roadmap

Priorities change with community input — upvote or comment on issues to influence them.

## Now (v0.1)
- Design system, Power BI / Tableau / Looker builder skills.
- Finance: P&L, AR & collections, AP & spend.
- Supply chain: inventory, order fulfillment & OTIF, procurement.
- Healthcare: revenue cycle, hospital operations.
- Sales pipeline; HR workforce.
- Installers for Claude Code, Codex, Antigravity, Kiro and others.

## Next
- **MCP server**: expose domain specs, metric definitions and platform patterns as MCP tools
  and resources (e.g. `list_domains`, `get_dashboard_spec`, `get_metric`,
  `translate_metric(platform)`), so any MCP-capable agent can use them without installing
  files.
- Machine-readable `spec.yaml` and `metrics.yaml` per domain skill (generated from, and
  validated against, the Markdown).
- Synthetic sample datasets per domain (CSV + DDL for Snowflake, BigQuery, Databricks).
- Evaluation suites: realistic prompts and questions with known answers to test skills.

## Later
- New domains: retail store performance, manufacturing OEE and quality, marketing campaign
  performance, customer success / SaaS metrics, insurance claims, banking credit risk,
  treasury & cash, project portfolio.
- Additional platforms: Microsoft Fabric / Direct Lake specifics, Tableau Next semantic
  metrics, Sigma, ThoughtSpot, Omni, Superset.
- Open Semantic Interchange (OSI) export of domain semantic models.
