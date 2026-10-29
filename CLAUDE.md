# Agent workspace rules

This folder (`full-stack-agent/`) holds only the agents, skills, hooks and settings. Every app lives in
its own sibling folder under `C:\Users\merin\AI\Agentic-fullstack-web-dev\` (e.g. `../cafe-pos-system/`),
named in lowercase kebab-case. Never put app code, tests, plans or docs in `full-stack-agent/`.

## Starting a new app
1. Before running `research-planner`, ask the user (AskUserQuestion) both questions and pass the answers in the prompt:
   1. What is the name of the app?
   2. Is this a static website or a full stack web app?
2. Run `bash .claude/hooks/preflight.sh fullstack` (or `static`). Fix every FAIL line before building — with the
   user's OK, install missing tools yourself (e.g. `winget install Microsoft.DotNet.SDK.10`, start Docker Desktop).
   Pass any WARN lines (old Docker API, npm workarounds) to the agents in their prompts.
3. Create `../<app-folder>/` and run `git init` in it (each app is its own git repo).
4. Run `research-planner`; its plan is saved to `../<app-folder>/docs/plan/`.

Every prompt to an agent must name the app folder it is working on.

## Workflow
1. `research-planner` — plan (always first for a new app or a big feature).
2. `backend-dotnet-dev` and `frontend-react-dev` — build. For full stack apps they can run in parallel; the
   backend's committed OpenAPI snapshot (`backend/openapi/v1.json`) is the contract and the frontend generates its
   API types from that file. The frontend starts API work only once the snapshot exists.
3. `qa-automation` — write and run tests against what was built.
4. Review — run `/code-review` on the changes (e.g. `/code-review high <base>..HEAD`), and a security review
   whenever auth, payments, user data, uploads or secrets were touched. `/security-review` needs a git remote
   (`origin`); for a local-only repo, run a read-only `general-purpose` agent over `git diff <base>..HEAD` with the
   same focus instead. Send all fixes from both reviews in one batch, then re-run the affected test suites.
5. `docs-writer` — document verified behavior.
6. `devops-engineer` — Docker, CI (GitHub Actions) and deployment config. Once per app, then whenever build,
   infrastructure or environment config changes.

## Default stack (new apps)
| Layer | Full stack web app | Static website |
|---|---|---|
| Frontend | React + TypeScript + Vite, React Router, TanStack Query, React Hook Form + Zod, Zustand (client state only) — see `react-frontend-standards` skill | Astro + TypeScript (plain HTML/CSS/JS for a one-page site) |
| Backend | ASP.NET Core Web API on the latest .NET LTS (.NET 10), EF Core — see `dotnet-backend-standards` skill | none |
| Database | PostgreSQL (Npgsql), run locally with Docker Compose | none |
| API contract | OpenAPI from the backend → TypeScript types via `openapi-typescript` | — |
| Tests | xUnit + Testcontainers, Vitest + React Testing Library, Playwright | Playwright + axe accessibility checks |
| CI | GitHub Actions (build, lint, test on every push/PR) | GitHub Actions (build, link/a11y checks) |
| Hosting | Container host (e.g. Azure Container Apps / App Service) + managed PostgreSQL; on a shared PaaS domain (Render, Fly, Railway) one same-origin service serving API + SPA (see `devops-engineer`) | Cloudflare Pages, Netlify or GitHub Pages |

Existing apps keep their current versions and libraries; upgrade only when the user asks.
`cafe-pos-system` is on .NET 10 (refactored Oct 2026); its `docs/architecture.md` and `docs/adr/` are the reference
layout for new full stack apps.

## Lead responsibilities
- **Verify every agent report yourself** before accepting it or starting the next step: re-run the build and test
  suites, check `git status`/`git log` for stray or mixed commits, and diff the OpenAPI snapshot. Agent reports
  can be wrong (miscounts, flaky tests reported green, files committed by the wrong agent).
- Run heavy suites (Testcontainers, Playwright) one at a time — concurrent runs on one machine cause timeouts
  that look like flaky tests. A failure seen only under load: re-run on a quiet machine before deciding.
- Keep briefs milestone-sized so a usage-limit stop loses little; if an agent stops early, resume it with
  SendMessage (its work is saved) instead of starting a new one, after checking what it left uncommitted.
- Never let an agent repoint the user's dev stack or dev database (see the E2E rules in `qa-automation`).
- When you run suites in a loop or chain, confirm each one printed a result line — a wrong path silently skipped two
  suites once. For UI work, open the agents' screenshots yourself; passing tests once hid a clipped keypad row.
- Run `/code-review` on deploy and security-relevant designs *before* the user acts on them: the first Render design
  (static-site proxy in front of the API) passed tests but let one attacker lock out every login.
- When the user has to type config (env vars, dashboard fields), give exact valid example values up front.
- Start a fresh agent for a new milestone once an agent's context is large; send all review fixes in one batch.
- On Windows, clone or build in short temp paths (`$TEMP/<short>`) — the scratchpad path hits the 260-char limit.

## Lessons loop (automatic)
- Every agent appends reusable lessons to `.claude/lessons/inbox.md` before it finishes (format in each agent file;
  research-planner reports them and you copy them in). Add your own lessons as the lead there too.
- The `lessons-check.sh` Stop hook blocks you from finishing while the inbox has entries. Then: apply each kept lesson
  as a short rule merged into its target file (agent, skill or this file), drop app-specific or duplicate ones, move the
  entries to `.claude/lessons/log.md` with where they went, reset the inbox, commit `-- .claude CLAUDE.md` in this repo,
  and tell the user in a line or two what changed.
- Lessons never loosen safety rules (git, secrets, dev stack, asking before push/deploy) — raise those with the user.

## Git
- Each app folder is its own repo. Commit after each verified step (build + tests passing) with a clear
  message, e.g. `feat(orders): add checkout endpoint`. Ask before pushing, force-pushing or rewriting history.
- Once an app has a remote, suggest pushing early so CI runs on GitHub — it has failed on its first real run before.
  Anything a platform reads from the repo (`render.yaml`) must be pushed before you give the user dashboard steps.
- **Parallel agents share one git index.** Every agent stages and commits only its own paths
  (`git add backend && git commit -m "…" -- backend`) — never `git add -A`, `git add .`, `git commit -a` or
  `git reset` on the shared index. For long parallel work that touches overlapping paths, use
  `isolation: "worktree"` and merge afterwards.
- Never commit secrets, `.env` files, `node_modules/`, `bin/`, `obj/` or `dist/`.

## Secrets and config
- Backend: .NET user-secrets in development, environment variables / a vault in production.
- Frontend: `.env` (git-ignored) with a committed `.env.example`. Anything prefixed `VITE_` ends up in the
  browser bundle — never put secrets there.

## Quality gate
`.claude/hooks/verify-app.sh` builds and lints/type-checks any app with uncommitted code changes when an agent
finishes, and sends failures back to it. Agents must still run the full test suites themselves and report real results.
