# Vendored third-party skills, commands and agents

Copied from upstream on 2026-10-30 after review (instructions read; bundled scripts checked for network, shell and
secret access). Upstream text is unchanged except the local changes listed. To update: re-clone at a newer commit,
review the diff, copy over, re-apply the local changes, and update this file.

| Item | Workspace path | Upstream | Commit | Licence | Local changes |
|---|---|---|---|---|---|
| brainstorming | `.claude/skills/brainstorming/` | github.com/obra/superpowers `skills/brainstorming` | `2ce8aa1` | MIT (`LICENSE`) | `description` narrowed: upstream "You MUST use this before any creative work…" triggered on every change |
| writing-plans | `.claude/skills/writing-plans/` | github.com/obra/superpowers `skills/writing-plans` | `2ce8aa1` | MIT | none (paths/git overridden in `research-planner.md`) |
| executing-plans | `.claude/skills/executing-plans/` | github.com/obra/superpowers `skills/executing-plans` | `2ce8aa1` | MIT | none |
| skill-creator | `.claude/skills/skill-creator/` | github.com/anthropics/skills `skills/skill-creator` | `ca45fc4` | Apache-2.0 (`LICENSE.txt`) | none |
| frontend-design | `.claude/skills/frontend-design/` | github.com/anthropics/claude-plugins-official `plugins/frontend-design/skills/frontend-design` | `f8c5e7a` | Apache-2.0 (`LICENSE.txt`) | none |
| ui-ux-pro-max | `.claude/skills/ui-ux-pro-max/` | github.com/nextlevelbuilder/ui-ux-pro-max-skill `.claude/skills/ui-ux-pro-max` | `28b3b8d` | MIT (`LICENSE`) | `scripts/tests/` dropped; script path given in `frontend-react-dev.md` (`${CLAUDE_PLUGIN_ROOT}` is unset for project skills) |
| feature-dev command | `.claude/commands/feature-dev.md` | github.com/anthropics/claude-plugins-official `plugins/feature-dev/commands` | `f8c5e7a` | Apache-2.0 (`_vendor-licenses/feature-dev-LICENSE`) | none |
| code-explorer, code-architect, code-reviewer | `.claude/agents/` | github.com/anthropics/claude-plugins-official `plugins/feature-dev/agents` | `f8c5e7a` | Apache-2.0 | none |
| Playwright MCP (not copied) | `mcpServers` in `.claude/agents/qa-automation.md` | npm `@playwright/mcp` (github.com/microsoft/playwright-mcp) | `0.0.83` pinned | Apache-2.0 | runs via `npx`; `browser_run_code_unsafe` disallowed |

Review notes:
- brainstorming's optional visual companion (`scripts/server.cjs`) is a local, token-protected web page that loads a
  logo from primeradiant.com; the planner is told to skip it.
- skill-creator's eval scripts run `claude -p` (spends tokens) — only on request.
- ui-ux-pro-max's scripts read local CSV/JSON only; needs `python` (3.x) — `python3` is the Microsoft Store stub here.
- Playwright MCP: Microsoft's browser server; `--isolated` (in-memory profile), installed Chrome (no browser download),
  output in `%TEMP%/qa-browser`. Its `browser_run_code_unsafe` runs arbitrary code in the server process, so QA may not
  use it. Bump the pinned version deliberately (read the changelog), never `@latest`.
