# GitHub Actions CI

Status: **implemented** — cafe-pos-system `d04812d` (full), IMMAN_HRIS `d4c2e28` (v1: backend, frontend, e2e, docker).
beth-online-shop: planned (D1, copy cafe-pos).

## Jobs (cafe-pos `cafe-pos-system/.github/workflows/ci.yml`)
| Job | Does |
|---|---|
| `backend` | setup-dotnet 10, restore, build Release, test (Testcontainers on ubuntu-latest), vulnerable-package check |
| `contract` | regenerate `backend/openapi/v1.json` and `frontend/src/api/schema.d.ts`, fail on `git diff` |
| `frontend` | Node 22, `npm ci`, lint, typecheck, format:check, test, build |
| `docker` | build API + web images (no `appsettings.Development.json`, refuses to start without `Jwt:Key`), build the single image, assert non-root, run `deploy/smoke-single-image.sh` |
| `e2e` | compose stack up `--wait`, Playwright `@smoke` on PRs, full on `main` + nightly cron, then `@layout|@a11y` projects; logs + report on failure; `down -v` |
| `migration-bundle` | main only: `dotnet restore -r linux-x64` then `dotnet ef migrations bundle -r linux-x64` → artifact |
Dependabot: `cafe-pos-system/.github/dependabot.yml`. IMMAN_HRIS: `IMMAN_HRIS/.github/workflows/ci.yml`.

## Port
Copy the workflow, rename paths/projects, keep pinned action majors (look up the latest live: `gh`, or
`curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest`). NuGet cache key includes
`Directory.Packages.props`, `Directory.Build.props`, `global.json`.

## Gotchas
- Guard steps after the stack start with `if: ${{ !cancelled() && steps.stack.outcome == 'success' }}`.
- A Playwright config with only the `list` reporter uploads an empty report: run `--reporter=list,html` in CI.
- `migrations bundle -r <rid>` fails on a fresh runner without `dotnet restore -r <rid>`.
- CI has not really run until it runs on GitHub: push early once a remote exists and fix the first run
  (the user runs git network commands — see [GitHub](../platforms/github.md)).
