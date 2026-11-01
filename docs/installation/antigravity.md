# Install in Google Antigravity

Antigravity loads workspace skills from `<workspace>/.agents/skills/` (older builds also read
`.agent/skills/`) and global skills from `~/.gemini/config/skills/` (legacy:
`~/.gemini/antigravity/skills/`). Skills must sit one level deep: `skills/<name>/SKILL.md`.

```bash
git clone https://github.com/venkat-vootl/semantic-model-dashboard-skills.git
cd semantic-model-dashboard-skills

# Global: all workspaces
./scripts/install.sh --agent antigravity --scope user

# Workspace: only the BI project you open in Antigravity
./scripts/install.sh --agent antigravity --scope project --target /path/to/workspace
```

Windows: `.\scripts\install.ps1 -Agent antigravity`.

If your Antigravity version still uses the legacy global folder, install with
`./scripts/install.sh --dest ~/.gemini/antigravity/skills`. Use copies (the default) rather
than `--link` if your version skips symlinked folders.

## Check it works

Open the agent side panel ▸ **Customizations** and confirm the skills are listed, then ask:

> Design a revenue cycle dashboard for our hospital in Looker, focused on denials by payer.

Reference: [Antigravity skills documentation](https://antigravity.google/docs/skills).
