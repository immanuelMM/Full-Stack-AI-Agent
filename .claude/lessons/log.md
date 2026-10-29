# Lessons log

Applied lessons, newest first. Each entry says where it was applied.

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
