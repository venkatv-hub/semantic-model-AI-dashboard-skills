# Agent Instructions for this Repository

These instructions are for AI coding agents (Claude Code, Codex, Antigravity, Kiro, Cursor…)
working **on** this repository — writing or improving skills. They are not the skills
themselves; those live in `skills/`.

## What this repo is
A library of Agent Skills (`SKILL.md` open format) that help agents design and build domain
dashboards in Power BI, Tableau and Looker. Three layers:
- `skills/bi-dashboard-design` — shared design system and the dashboard spec format.
- `skills/{powerbi,tableau,looker}-dashboard-builder` — platform implementation.
- `skills/<domain>-<area>-dashboard` — domain knowledge, each with `references/metrics.md`.

## Rules when editing
1. Keep `name` equal to the folder name; keep `description` ≤ 1024 characters, third person,
   saying what the skill builds and when to use it. No angle brackets in descriptions.
2. Keep each `SKILL.md` under 500 lines; move detail into `references/` and link it with a
   backtick path such as `references/metrics.md` (the validator checks these exist).
3. Every metric used on a page must be defined in that skill's `references/metrics.md`.
4. Domain skills must reference `bi-dashboard-design` and the platform builder skills rather
   than duplicating their content.
5. Use synthetic examples only; never add real customer, patient or employee data.
6. When adding or renaming a skill, update `.claude-plugin/marketplace.json`, then run:
   ```bash
   python3 scripts/skills.py validate
   python3 scripts/skills.py catalog
   ```
7. Add an entry under "Unreleased" in `CHANGELOG.md` for user-visible changes.

## Testing a skill locally
Install into a scratch project with `./scripts/install.sh --agent <agent> --scope project
--target <scratch-dir>` and prompt the agent with a realistic request. Check that it writes a
dashboard spec first, uses the domain metric definitions, and follows the platform builder.
