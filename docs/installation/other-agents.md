# Install in other agents

The skills follow the open [Agent Skills](https://agentskills.io) format (a folder with a
`SKILL.md` that has `name` and `description` frontmatter, plus optional `references/`), so
they work in any agent that supports it — for example Cursor, GitHub Copilot in VS Code, and
Gemini CLI.

1. Find your agent's skills folder in its documentation (many tools read the shared
   `.agents/skills` folder in a project or `~/.agents/skills` for the user).
2. Install there:

   ```bash
   ./scripts/install.sh --agent agents --scope project --target /path/to/project   # .agents/skills
   ./scripts/install.sh --dest /path/to/agent/skills                                  # any folder
   ```

3. Restart the agent and ask for a dashboard in plain language.

## Agents without skills support

Paste the relevant `SKILL.md` (and `references/metrics.md`) into the agent's rules or
system-prompt file, or attach them to the conversation. Load `bi-dashboard-design`, one
builder, and one domain skill at a time to keep context small.

## Coming soon: MCP

An MCP server exposing the same domain specs and metric definitions is on the
[roadmap](../../ROADMAP.md). Any MCP-capable agent will be able to use the skills without
copying files.
