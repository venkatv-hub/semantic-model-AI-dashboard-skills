# Install in Kiro (IDE and CLI)

Kiro supports Agent Skills in `.kiro/skills/` (workspace) and `~/.kiro/skills/` (global).
Workspace skills win when names clash.

## Option 1 — Import from GitHub in the Kiro IDE

1. Open the **Agent Steering & Skills** section in the Kiro panel.
2. Click **+ ▸ Import a skill** and paste the GitHub URL of a skill folder, for example
   `https://github.com/venkat-vootl/semantic-model-dashboard-skills/tree/main/skills/bi-dashboard-design`.
3. Repeat for the builder skill(s) and domain skills you need.

## Option 2 — Install script (all skills at once)

```bash
git clone https://github.com/venkat-vootl/semantic-model-dashboard-skills.git
cd semantic-model-dashboard-skills
./scripts/install.sh --agent kiro --scope user                 # global
./scripts/install.sh --agent kiro --scope project --target .   # this workspace
```

Windows: `.\scripts\install.ps1 -Agent kiro`.

## Kiro CLI custom agents

The default agent picks up skills automatically. For a custom agent, add the skills to its
resources:

```json
{
  "name": "bi-builder",
  "resources": [
    "skill://.kiro/skills/*/SKILL.md",
    "skill://~/.kiro/skills/*/SKILL.md"
  ]
}
```

## Check it works

Type `/` in chat to see skills as slash commands, or ask:

> Build an AP and spend dashboard spec for Tableau. Our ERP is SAP S/4HANA.

Reference: [Kiro Agent Skills](https://kiro.dev/docs/skills/).
