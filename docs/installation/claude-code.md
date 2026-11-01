# Install in Claude Code

Two options. Install **all** skills: domain skills rely on `bi-dashboard-design` and the
platform builders.

## Option 1 — Plugin marketplace (recommended)

Inside Claude Code:

```
/plugin marketplace add venkat-vootl/semantic-model-dashboard-skills
/plugin install semantic-model-dashboard-skills@bi-skills
```

Or run `/plugin`, choose the `bi-skills` marketplace, select `semantic-model-dashboard-skills` and
"Install now". Update later with `/plugin marketplace update bi-skills`.

## Option 2 — Copy or link the skills

```bash
git clone https://github.com/venkat-vootl/semantic-model-dashboard-skills.git
cd semantic-model-dashboard-skills

# All projects (personal skills in ~/.claude/skills)
./scripts/install.sh --agent claude --scope user

# One project only (committed with that project in .claude/skills)
./scripts/install.sh --agent claude --scope project --target /path/to/your/project

# Keep them updated with `git pull` by linking instead of copying
./scripts/install.sh --agent claude --scope user --link
```

Windows (PowerShell):

```powershell
.\scripts\install.ps1 -Agent claude
```

## Check it works

Start a new session and ask: *"What skills do you have for BI dashboards?"* — then try:

> Build a P&L budget-vs-actual dashboard spec for Power BI. Fiscal year starts in April.

Claude should load `finance-pnl-dashboard` and `bi-dashboard-design`, ask at most a few
questions, and show a dashboard spec before building.

## Working with Power BI, Tableau or Looker tools

The builder skills use live tools when they are connected and fall back to writing files:

- **Power BI:** Microsoft's Power BI Modeling MCP server
  (`claude mcp add powerbi-modeling -- npx -y @microsoft/powerbi-modeling-mcp@latest`) or
  `pbi-cli`, with Power BI Desktop open; or save your report as a `.pbip` project and point
  Claude at the folder.
- **Tableau:** the Tableau MCP server, or a saved `.tds` data source in your project folder.
- **Looker:** a local clone of your LookML repository; optionally Looker's MCP/Toolbox tools.

Check each vendor's documentation for current installation commands and required
permissions.
