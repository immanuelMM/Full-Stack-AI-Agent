# Agent workspace rules

This folder (`full-stack-agent/`) holds only the agents, skills, hooks and settings. Every app lives in
its own sibling folder under `C:\Users\merin\AI\Agentic-fullstack-web-dev\` (e.g. `../cafe-pos-system/`),
named in lowercase kebab-case. Never put app code, tests, plans or docs in `full-stack-agent/`.

Knowledge is split in two:
- **Standards** — agents (`.claude/agents/`) and skills (`.claude/skills/`): short, general rules for how to build any
  web app. No app names, no platform trivia, no incident stories.
- **Knowledge base (LLM wiki)** — `.claude/wiki/`: what was already built and how. One page per app, per reusable
  feature (auth, touch shell, checkout, QR attendance, …) and per platform/provider (Render, PayMongo, …), each
  pointing at the working code in an app folder. The wiki holds pointers and recipes only, never app code.

## Reuse before you build
- Before planning or building a feature, read `.claude/wiki/index.md`. If a feature page matches, reuse its reference
  implementation (copy and adapt the files it names) and its decisions instead of researching or designing it again;
  research only what the page marks as unknown or what differs.
- Name the matching wiki pages in every agent prompt, so agents read them instead of exploring.

## Starting a new app
1. Before running `research-planner`, ask the user (AskUserQuestion) both questions and pass the answers in the prompt:
   1. What is the name of the app?
   2. Is this a static website or a full stack web app?
2. Run `bash .claude/hooks/preflight.sh fullstack` (or `static`). Fix every FAIL line before building — with the
   user's OK, install missing tools yourself (e.g. `winget install Microsoft.DotNet.SDK.10`, start Docker Desktop).
   Pass any WARN lines (old Docker API, npm workarounds) to the agents in their prompts.
3. Create `../<app-folder>/` and run `git init` in it (each app is its own git repo).
4. Add `.claude/wiki/apps/<app-folder>.md` (purpose, stack, status) and list it in the wiki index.
5. Run `research-planner`; its plan is saved to `../<app-folder>/docs/plan/`.

Every prompt to an agent must name the app folder it is working on.

## Workflow
1. `research-planner` — plan (always first for a new app; for a big feature in an existing app it runs after the
   code explorers, see `/feature-dev` below).
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

## Skills and lead tools
| Who | Skills / tools | Source |
|---|---|---|
| research-planner | `brainstorming`, `writing-plans`, `executing-plans` (superpowers), `skill-creator` | obra/superpowers (MIT), anthropics/skills (Apache-2.0) |
| frontend-react-dev | `react-frontend-standards`, `frontend-design`, `ui-ux-pro-max` | anthropics/claude-plugins-official (Apache-2.0), nextlevelbuilder/ui-ux-pro-max-skill (MIT) |
| backend-dotnet-dev | `dotnet-backend-standards` | workspace |
| qa-automation | Playwright MCP — a visible Chrome it drives step by step (server defined in the agent file) | microsoft/playwright-mcp (Apache-2.0), npm `@playwright/mcp@0.0.83` |
| lead | `/feature-dev` command + `code-explorer`, `code-architect`, `code-reviewer` agents | anthropics/claude-plugins-official (Apache-2.0) |
- Third-party skills are vendored unchanged except where `.claude/skills/VENDOR.md` says; update them from there.
- **Workspace rules win** over any skill or command text (git staging, no push without asking, `docs/plan/` paths,
  dev-stack isolation, secrets). Skip steps that reference skills not installed here.
- `/feature-dev` for a big feature in an existing app, in this order: discovery → 2–3 `code-explorer` agents trace the
  code → your clarifying questions → `research-planner` (pass the explorers' findings, key files and the user's
  answers; it researches only what is new and saves the plan to `docs/plan/`) → 2–3 `code-architect` agents turn that
  plan into blueprint options → the user picks one → build agents per the Workflow. In the review step use
  `code-reviewer` alongside `/code-review`.
- Brainstorm with the user yourself (the `brainstorming` skill) when a new app's request is vague; subagents can't ask
  the user, so the planner returns its questions with defaults.

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
The reference layout for new full stack apps (architecture doc, ADRs, scaffold) is named in `.claude/wiki/index.md`.

## Lead responsibilities
- **Verify every agent report yourself** before accepting it or starting the next step: re-run the build and test
  suites, check `git status`/`git log` for stray or mixed commits, and diff the OpenAPI snapshot. Agent reports
  can be wrong (miscounts, flaky tests reported green, files committed by the wrong agent).
- Run heavy suites (Testcontainers, Playwright) one at a time — concurrent runs on one machine cause timeouts
  that look like flaky tests. A failure seen only under load: re-run on a quiet machine before deciding.
- Keep briefs milestone-sized so a usage-limit stop loses little; if an agent stops early, resume it with
  SendMessage (its work is saved) instead of starting a new one, after checking what it left uncommitted.
- Never let an agent repoint the user's dev stack or dev database (see the E2E rules in `qa-automation`).
- When you run suites in a loop or chain, confirm each one printed a result line (a wrong path skips silently). For UI
  work, open the agents' screenshots yourself — passing tests miss clipped controls.
- Run `/code-review` on deploy and security-relevant designs *before* the user acts on them; passing tests don't prove
  a design safe.
- When the user has to type config (env vars, dashboard fields), give exact valid example values up front. Before
  telling them to delete one-time credentials (bootstrap vars), have them confirm they actually logged in.
- Changes to agents, skills or MCP servers in `.claude/` load only in a new Claude Code session: restart before relying on them.
- Start a fresh agent for a new milestone once an agent's context is large; send all review fixes in one batch.
- Clone or build in short temp paths (`$TEMP/<short>`), never the scratchpad (Windows 260-char limit; see the wiki's windows page).

## Lessons loop (automatic)
- Every agent appends reusable lessons to `.claude/lessons/inbox.md` before it finishes (format in each agent file;
  research-planner reports them and you copy them in). Add your own lessons as the lead there too.
- The `lessons-check.sh` Stop hook blocks you from finishing while the inbox has entries. Then route each entry:
  - a **general rule** (true for any web app) → merge it as one short imperative line into its agent, skill or this
    file; no story, no app name;
  - **app, feature or platform knowledge** (where something is implemented, a provider quirk, a decision) → the matching
    `.claude/wiki/` page (create it and list it in the index if new);
  - duplicates → drop.
  Move the entries to `.claude/lessons/log.md` with where they went, reset the inbox, commit `-- .claude CLAUDE.md` in
  this repo, and tell the user in a line or two what changed.
- After each verified milestone, update the app's wiki page (status, where features live) and add or update a feature
  page for anything another app could reuse.
- Lessons never loosen safety rules (git, secrets, dev stack, asking before push/deploy) — raise those with the user.

## Git
- Each app folder is its own repo. Commit after each verified step (build + tests passing) with a clear
  message, e.g. `feat(orders): add checkout endpoint`. Ask before pushing, force-pushing or rewriting history.
- Once an app has a remote, suggest pushing early so CI really runs on GitHub. Anything a platform reads from the repo
  (`render.yaml`) must be pushed before you give dashboard steps (who runs git network commands: wiki `platforms/github.md`).
- **Parallel agents share one git index.** Every agent stages and commits only its own paths
  (`git add backend && git commit -m "…" -- backend`) — never `git add -A`, `git add .`, `git commit -a`,
  `git reset` or a plain `git stash` on the shared tree (it hides other agents' uncommitted work); to test without a
  change, use `git stash push -- <own paths>` or a throwaway `git worktree`. For long parallel work that touches overlapping paths, use
  `isolation: "worktree"` and merge afterwards.
- Never commit secrets, `.env` files, `node_modules/`, `bin/`, `obj/` or `dist/`.

## Secrets and config
- Backend: .NET user-secrets in development, environment variables / a vault in production.
- Frontend: `.env` (git-ignored) with a committed `.env.example`. Anything prefixed `VITE_` ends up in the
  browser bundle — never put secrets there.

## Quality gate
`.claude/hooks/verify-app.sh` builds and lints/type-checks any app with uncommitted code changes when an agent
finishes, and sends failures back to it — once per session per failure (`handback-guard.sh`), so a teammate whose
spawning agent has exited, or one blocked by another agent's work, can still finish; you catch the rest when verifying. Agents must still run the full test suites themselves and report real results.
