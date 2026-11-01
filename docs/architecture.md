# Architecture

## Three layers of skills

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Domain skills (what)                                                       │
│ finance-pnl · finance-ar · finance-ap · supply-chain-inventory · …         │
│ decisions · data model · metric definitions · pages · drill paths · rules │
└───────────────┬───────────────────────────────────────┬──────────────────┘
                │ produce a dashboard spec               │ metric definitions
                ▼                                        ▼
┌──────────────────────────────────┐   ┌───────────────────────────────────┐
│ bi-dashboard-design (how it looks)│   │ Platform builders (how it's built) │
│ tiers · grid · components · color │──►│ powerbi · tableau · looker          │
│ spec format · acceptance checks   │   │ model · measures · pages · security │
└──────────────────────────────────┘   └───────────────────────────────────┘
```

Agents load skills progressively: at start-up only names and descriptions are read; a
skill's `SKILL.md` is loaded when the request matches; `references/` files are read only when
the instructions point to them. That keeps context small even with many skills installed.

## The flow of one request

1. **Match** – "Build an AR dashboard in Power BI" matches
   `finance-ar-collections-dashboard` (domain) and `powerbi-dashboard-builder` (platform).
2. **Frame** – the domain skill asks for, or defaults, the definitions that change numbers
   (DSO method, aging basis, target).
3. **Spec** – the agent writes a dashboard spec (format in
   `skills/bi-dashboard-design/references/dashboard-spec.md`) and shows it to the user.
4. **Build** – the platform builder chooses a build mode (live tools, files, or a build kit)
   and implements the model, measures and pages using the domain's `metrics.md`.
5. **Verify** – reconciliation and the acceptance checklist; unresolved items are reported.

## Why a spec in the middle?

- Business users can review a one-page spec; they can't review TMDL or LookML.
- The same spec can be built on any platform, which also makes it the natural unit for
  migrations (e.g. Tableau → Power BI) and for the planned MCP server.

## Planned MCP server

The MCP server will expose the same content as tools and resources:
- `list_domains`, `get_domain_skill(domain)`
- `get_dashboard_spec(domain, platform, tier)`
- `get_metric(domain, metric, platform)` → definition plus DAX / Tableau / LookML
- `validate_spec(spec)`

The Markdown skills remain the source of truth; the server reads them.
