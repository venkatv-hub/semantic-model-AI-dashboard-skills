# Install in OpenAI Codex (CLI, IDE extension, app)

Codex reads Agent Skills from `.agents/skills` folders: in the repository (from the current
directory up to the repo root) and in `~/.agents/skills` for personal skills.

```bash
git clone https://github.com/venkat-vootl/semantic-model-dashboard-skills.git
cd semantic-model-dashboard-skills

# Personal: available in every repository
./scripts/install.sh --agent codex --scope user

# Team: commit the skills inside your BI project repository
./scripts/install.sh --agent codex --scope project --target /path/to/your/bi-repo
```

Windows: `.\scripts\install.ps1 -Agent codex`.

Older Codex versions used `~/.codex/skills`; if your version doesn't list the skills, install
there with `./scripts/install.sh --dest ~/.codex/skills`.

## Check it works

Run `/skills` in the Codex CLI (or type `$` to mention a skill) and confirm the
`finance-*`, `supply-chain-*`, `healthcare-*` and builder skills appear. Then try:

> Use $supply-chain-inventory-dashboard to design an inventory health dashboard in Looker for
> our BigQuery dataset `sc_analytics`.

Reference: [Codex Agent Skills](https://developers.openai.com/codex/skills).
