# Semantic Model Dashboard Skills

**Domain-aware dashboard skills for AI agents — finance, supply chain, healthcare, sales and
HR dashboards built the same professional way in Power BI, Tableau and Looker.**

An open-source project by **Venkat V**. Works with Claude (Claude Code and the Claude apps),
OpenAI Codex, Google Antigravity, Kiro, and any agent that supports the open
[Agent Skills](https://agentskills.io) `SKILL.md` format.

> **Status:** early release (v0.1). We are adding domains and drill-downs continuously, and an
> **MCP server** version is coming soon so any MCP-capable agent can pull these definitions
> on demand. Contributions are very welcome — see [Contributing](#contributing).

---

## Why this exists

AI agents can already write DAX, LookML and Tableau calcs. What they lack is **domain
judgment**: which KPIs a CFO actually looks at, how DSO should be calculated, why inventory
must never be summed across snapshots, what an executive page should *not* contain, and how a
healthcare dashboard stays PHI-safe.

This repository packages that judgment as skills:

| Layer | What it decides | Skills |
|---|---|---|
| **Domain skills** | *What* to show: decisions supported, canonical data model, metric definitions, page-by-page layout, drill paths, domain gotchas | `finance-*`, `supply-chain-*`, `healthcare-*`, `sales-*`, `hr-*` |
| **Design system** | *How it looks*: level-of-detail tiers, 12-column grid, KPI card anatomy, chart selection, color, formatting, accessibility | `bi-dashboard-design` |
| **Platform builders** | *How it is built* on each tool: semantic model, measures, report pages, security | `powerbi-dashboard-builder`, `tableau-dashboard-builder`, `looker-dashboard-builder` |

```
 "Build an AR collections dashboard in Looker"
          │
          ▼
 finance-ar-collections-dashboard ──► dashboard spec (YAML) ──► user confirms
          │                                    │
          ├── bi-dashboard-design (layout, components, colors)
          ▼                                    ▼
 looker-dashboard-builder ──► views / explores / model / .dashboard.lookml
```

Every domain skill produces the **same dashboard spec format** first, so the user reviews one
short document before anything is built, and the same spec can be built in any of the three
platforms.

## Skills

See **[CATALOG.md](CATALOG.md)** for the full, auto-generated list. Currently:

| Domain | Skills |
|---|---|
| Finance | P&L / budget vs actual · AR & collections · AP & spend |
| Supply chain | Inventory health · Order fulfillment & OTIF · Procurement & supplier performance |
| Healthcare | Revenue cycle (RCM) · Hospital operations & patient flow |
| Sales | Pipeline & forecast |
| HR | Workforce & attrition |
| Core | Dashboard design system · Power BI builder · Tableau builder · Looker builder |

Each domain skill contains:
- `SKILL.md` — decisions supported, canonical star schema, KPI list with direction
  ("higher is better"), L1/L2/L3 page layouts, drill paths, filters, domain rules and gotchas,
  platform notes, and a "done when" checklist.
- `references/metrics.md` — precise metric definitions (formula, additivity, edge cases) and
  ready-to-adapt implementations in **DAX, Tableau calculations and LookML**.

## Quick start

Install **all** skills together — domain skills rely on the design system and the platform
builders.

| Agent | Fastest path | Guide |
|---|---|---|
| Claude Code | `/plugin marketplace add venkat-vootl/semantic-model-dashboard-skills` then `/plugin install semantic-model-dashboard-skills@bi-skills` | [docs/installation/claude-code.md](docs/installation/claude-code.md) |
| Claude apps (web, desktop) | Upload each skill folder as a custom skill | [docs/installation/claude-apps.md](docs/installation/claude-apps.md) |
| OpenAI Codex | `./scripts/install.sh --agent codex` | [docs/installation/codex.md](docs/installation/codex.md) |
| Google Antigravity | `./scripts/install.sh --agent antigravity` | [docs/installation/antigravity.md](docs/installation/antigravity.md) |
| Kiro | `./scripts/install.sh --agent kiro` or import from GitHub in the Kiro panel | [docs/installation/kiro.md](docs/installation/kiro.md) |
| Cursor, GitHub Copilot, Gemini CLI, others | Copy `skills/*` into the agent's skills folder | [docs/installation/other-agents.md](docs/installation/other-agents.md) |

On Windows (where Power BI Desktop runs) use `scripts/install.ps1` with the same options.

```bash
git clone https://github.com/venkat-vootl/semantic-model-dashboard-skills.git
cd semantic-model-dashboard-skills
./scripts/install.sh --agent claude --scope user        # or codex | antigravity | kiro
```

## Try it

Once installed, just ask in plain language — the agent picks the right skills:

- "Build an accounts receivable dashboard in Power BI on our Snowflake `FINANCE.AR` schema.
  DSO target is 45 days."
- "Design an OTIF dashboard for our distribution centers in Tableau. Use promised date, not
  requested date."
- "Create LookML and a dashboard for hospital denials management by payer and CARC code."
- "Give me the spec for a CFO P&L dashboard with budget vs actual — we don't know the
  platform yet."
- "Review this Power BI page against the executive-tier rules."

What to expect: the agent asks at most a few questions (platform, data source, definitions
that change the numbers), shows a dashboard spec, and then builds the semantic model, measures
and pages — or a build kit if it can't write files in your environment.

## Repository layout

```
skills/                      # one folder per skill (SKILL.md + references/)
templates/                   # starting point for new domain skills
docs/installation/           # per-agent setup guides
docs/architecture.md         # how the skills fit together
scripts/install.sh|.ps1      # install into Claude, Codex, Antigravity, Kiro, Cursor…
scripts/skills.py            # validate skills and regenerate CATALOG.md
.claude-plugin/              # Claude Code plugin marketplace manifest
.github/                     # CI, issue and PR templates
```

## Roadmap

- **MCP server** exposing domain specs, metric definitions and platform patterns as tools and
  resources (coming soon).
- More domains: retail store performance, manufacturing OEE, marketing campaigns, customer
  success / SaaS metrics, insurance claims, banking risk.
- Synthetic sample datasets per domain and evaluation suites (questions with known answers).
- Machine-readable spec and metric files (YAML) alongside each skill.

See [ROADMAP.md](ROADMAP.md) and open an issue to vote on what comes next.

## Contributing

We want this to become the community's reference for domain dashboards. You can contribute:

- a **new domain skill** (start from `templates/domain-dashboard-skill/`),
- **new pages, drill-downs or metrics** for an existing domain,
- **platform patterns** (better DAX, LookML, Tableau or Tableau Next techniques),
- **fixes** to definitions you can back with a source or real-world practice.

Read [CONTRIBUTING.md](CONTRIBUTING.md), run `python3 scripts/skills.py validate`, and open a
pull request. Every PR is reviewed by a maintainer before merge.

## Security and privacy

Skills contain instructions and examples only — no credentials, no customer data. Never
include real PHI, PII or customer data in issues or pull requests. See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Venkat V.
