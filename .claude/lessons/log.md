# Lessons log

Applied lessons, newest first. Each entry says where it was applied.

## 2026-10-30 · cafe-pos-system (backend-dotnet-dev) · tooling
- Applied to backend-dotnet-dev Constraints (Write/Edit over heredocs; no `using var _`).
### 2026-10-30 · backend-dotnet-dev · cafe-pos-system
- target: .claude/agents/backend-dotnet-dev.md
- lesson: Write multi-line C# or Python files with the Write/Edit tools, not Bash heredocs; in this environment heredocs containing quotes failed with "unexpected EOF" and applied nothing. Also never name a using variable `_` in tests (CS1656).
- why: two heredoc attempts failed silently before any file changed; `using var _ = factory` broke the build.

## 2026-10-30 · cafe-pos-system (lead) · owner recovery
- Applied to devops-engineer (first-user bullet: ship a recovery path) and CLAUDE.md (confirm login before deleting bootstrap vars).
### 2026-10-30 · lead · cafe-pos-system
- target: .claude/agents/devops-engineer.md (and CLAUDE.md lead section)
- lesson: Any first-user bootstrap ships together with a config-driven recovery path (one-time owner password reset + lockout clear), and the lead confirms the user has actually logged in before telling them to delete the bootstrap settings.
- why: On Render (no shell) the user deleted the bootstrap vars and then couldn't log in; there was no way back without a new backend feature and a redeploy.

## 2026-10-30 · cafe-pos-system (Render deploy + tablet UI refactor)
Applied directly by the lead in `chore(agents): apply Render + tablet UI lessons`:
- devops-engineer: single same-origin service on Public Suffix List domains; no proxy hop or hard-coded platform
  hostname; internal-only DB; trust only the private LB range; `DATABASE_URL` in the app; first-owner bootstrap with
  example values; push before dashboard steps; `migrations bundle -r` needs `restore -r`; build + smoke the prod image
  in CI; guard follow-up CI steps on the stack step's outcome.
- backend-dotnet-dev: non-crashing startup helpers; owner bootstrap rules; `DATABASE_URL`; `ForwardLimit`; SPA fallback
  must not swallow API routes.
- frontend-react-dev + react-frontend-standards: screenshots at each size are looked at; size rules scoped inside their
  queries; tablet/touch rules (one DOM, dvh shell, 56/64/48px, keypad with real input, 375×667); auto-print limits;
  relative API base; format:check covers Markdown; never prettier generated files.
- qa-automation: viewport projects + layout helpers; visual baseline for no-visual-change refactors; stub `window.print`;
  navigate like the user per size; restock drained stock.
- research-planner: flag platform limits; Public Suffix List check; Decisions section.
- CLAUDE.md: lead verification (check every suite printed a result, look at screenshots), push early, give exact config
  values, fresh agents per milestone, short temp paths on Windows, the lessons loop itself.
