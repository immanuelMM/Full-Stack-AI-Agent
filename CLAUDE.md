# Agent workspace rules

This folder (`full-stack-agent/`) holds only the agents, skills, hooks and settings. Every app lives in
its own sibling folder under `C:\Users\merin\AI\Agentic-fullstack-web-dev\` (e.g. `../cafe-pos-system/`),
named in lowercase kebab-case. Never put app code, tests, plans or docs in `full-stack-agent/`.

## Starting a new app
1. Before running `research-planner`, ask the user (AskUserQuestion) both questions and pass the answers in the prompt:
   1. What is the name of the app?
   2. Is this a static website or a full stack web app?
2. Create `../<app-folder>/` and run `git init` in it (each app is its own git repo).
3. Run `research-planner`; its plan is saved to `../<app-folder>/docs/plan/`.

Every prompt to an agent must name the app folder it is working on.

## Workflow
1. `research-planner` — plan (always first for a new app or a big feature).
2. `backend-dotnet-dev` and `frontend-react-dev` — build. For full stack apps they can run in parallel; the
   backend's OpenAPI spec is the contract and the frontend generates its API types from it.
3. `qa-automation` — write and run tests against what was built.
4. Review — run `/code-review` on the changes, and `/security-review` whenever auth, payments, user data or
   secrets were touched.
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
| Hosting | Container host (e.g. Azure Container Apps / App Service) + managed PostgreSQL | Cloudflare Pages, Netlify or GitHub Pages |

Existing apps keep their current versions and libraries; upgrade only when the user asks.
Note: `cafe-pos-system` targets .NET 8, which reaches end of support on 10 Nov 2026 — recommend the .NET 10 upgrade.

## Git
- Each app folder is its own repo. Commit after each verified step (build + tests passing) with a clear
  message, e.g. `feat(orders): add checkout endpoint`. Ask before pushing, force-pushing or rewriting history.
- Never commit secrets, `.env` files, `node_modules/`, `bin/`, `obj/` or `dist/`.

## Secrets and config
- Backend: .NET user-secrets in development, environment variables / a vault in production.
- Frontend: `.env` (git-ignored) with a committed `.env.example`. Anything prefixed `VITE_` ends up in the
  browser bundle — never put secrets there.

## Quality gate
`.claude/hooks/verify-app.sh` builds and lints/type-checks any app with uncommitted code changes when an agent
finishes, and sends failures back to it. Agents must still run the full test suites themselves and report real results.
