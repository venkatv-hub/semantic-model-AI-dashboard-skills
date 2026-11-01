# Contributing to Semantic Model Dashboard Skills

Thanks for helping build the reference library of domain dashboards for AI agents. This guide
covers what we accept, how to structure a skill, and how pull requests are reviewed.

## What we welcome

| Contribution | Examples |
|---|---|
| New domain skill | Retail store performance, manufacturing OEE, insurance claims, SaaS metrics, marketing campaigns |
| New page or drill-down in an existing skill | Collector productivity page for AR, carrier claims page for fulfillment |
| New or corrected metric definition | A missing KPI, an edge case, a better formula with a cited source |
| Platform patterns | Better DAX, LookML or Tableau techniques; Tableau Next or Fabric specifics |
| Installation guides | Steps for another agent or IDE |
| Bug reports | A definition that gives a wrong number, a pattern that fails to validate |

Not accepted: customer-specific dashboards, real customer data, vendor marketing, or skills
that require proprietary software beyond the BI platform itself.

## Before you start

1. Search existing issues and skills to avoid duplicates.
2. For a **new domain skill**, open a "New skill proposal" issue first so we can agree on scope
   and naming.
3. Small fixes (typos, a formula correction with a source) can go straight to a PR.

## Skill structure

```
skills/<domain>-<area>-dashboard/
├── SKILL.md              # required: frontmatter + instructions (< 500 lines)
└── references/
    └── metrics.md        # required for domain skills: definitions + DAX/Tableau/LookML
```

Start from `templates/domain-dashboard-skill/`.

### Naming
- Folder name = `name` in frontmatter: lowercase letters, digits and hyphens, ≤ 64 characters.
- Domain skills: `<domain>-<area>-dashboard` (e.g. `finance-treasury-dashboard`).
- Platform skills: `<platform>-dashboard-builder`.
- Do not use the words "claude" or "anthropic" in skill names.

### Frontmatter
```yaml
---
name: finance-treasury-dashboard
description: Designs and builds a treasury and cash position dashboard — … — in Power BI, Tableau or Looker. Use this skill whenever the user asks for …, even if they only say "…".
---
```
- `description` is how agents decide to load the skill. Say **what it builds** and **when to
  use it**, include the words real users type (synonyms, acronyms), stay under 1024
  characters, and don't use angle brackets.
- Only `name` and `description` are used so the skill works in every agent.

### Content quality bar
A domain skill must:
- state the **decisions** the dashboard supports;
- define a **canonical data model** with the grain of every fact table;
- list metrics with **direction** (higher is better / lower / target band) and tier;
- describe **L1, L2 and L3 pages** using the components and grid from `bi-dashboard-design`;
- call out **definition choices** that change the number, with a default;
- include **domain gotchas** (additivity, sign conventions, timing, privacy);
- give **DAX, Tableau and LookML** for the 3–6 most important metrics in `metrics.md`;
- end with a **"Done when"** checklist including a reconciliation step.

Write instructions in the imperative, explain *why* a rule exists, and prefer defaults plus
"confirm with the user" over hard requirements. Keep `SKILL.md` focused; put long material in
`references/` and point to it.

### Data and privacy
- Use synthetic names and numbers only. No real customer, patient or employee data.
- Healthcare and HR skills must keep PHI/PII out of the semantic model by default and include
  suppression / row-level security guidance.

## Local checks

```bash
python3 scripts/skills.py validate      # frontmatter, names, references, marketplace listing
python3 scripts/skills.py catalog       # regenerate CATALOG.md after adding/renaming a skill
```

When you add a skill, also add its path to `.claude-plugin/marketplace.json` under
`plugins[0].skills`. CI fails if the catalog or marketplace is out of date.

Test the skill in at least one agent: install it, ask for the dashboard with a realistic
prompt, and check that the spec and outputs follow the skill. Mention the agent and platform
you tested with in the PR.

## Pull request process

1. Fork, create a branch (`feat/finance-treasury`, `fix/ar-dso-countback`).
2. Make your change and run the local checks.
3. Open a PR using the template; link the issue.
4. A maintainer reviews within about a week. Domain changes get a domain review (does the
   definition match practice?) and a platform review (does the code run?).
5. We squash-merge with a conventional commit title (`feat(finance): add treasury dashboard`).

By submitting a contribution you confirm you have the right to contribute it and agree that it
is licensed under the repository's [MIT License](LICENSE).

## Style

- Markdown, 100-character soft wrap, ATX headings (`#`), fenced code blocks with a language.
- Use business names (`Net Revenue`), not database names, in visible text.
- Use the semantic color tokens from `bi-dashboard-design`; don't invent new palettes.

## Code of conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md).
