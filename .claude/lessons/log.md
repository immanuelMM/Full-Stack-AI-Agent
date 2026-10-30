# Lessons log

Applied lessons, newest first. Each entry says where it was applied.

## 2026-10-30 · IMMAN_HRIS U0 baseline (qa-automation)
- Applied to qa-automation: zero-tolerance screenshot flags + 3-frame check (E2E rules, visual baseline bullet); Write/Edit over heredocs (Constraints; second time it bit an agent).
### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: For a zero-tolerance screenshot baseline, mock `/api/**` with `context.route`, freeze the date with `page.clock.setFixedTime`, stub `getUserMedia`, launch Chromium with `--disable-gpu --disable-lcd-text --font-render-hinting=none --force-color-profile=srgb --disable-gpu-compositing --disable-partial-raster`, and shoot until 3 consecutive frames are byte-identical; never add `--disable-threaded-compositing` (screenshots fail with "Unable to capture screenshot").
- why: with only a 2-frame stability check and no flags, a double run differed by 10-70 px (rounded-corner and canvas text antialiasing) on 1-5 of 80 shots; with the flags plus the 3-frame check three double runs gave 80/80 identical.
### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: When Bash heredocs with several quotes/apostrophes in one command fail with "unexpected EOF while looking for matching quote", write the files with the Write tool instead of retrying the heredoc.
- why: two multi-file `cat <<'EOF'` commands failed to parse on Windows Git Bash and wrote nothing.

## 2026-10-30 · IMMAN_HRIS F3 (backend-dotnet-dev)
- Applied to dotnet-backend-standards §7 Secrets: env-scoped fail-fast validator with a unit test; grep all consumers before removing a committed secret.
### 2026-10-30 · backend-dotnet-dev · IMMAN_HRIS
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: When removing a committed secret from appsettings.json, grep every consumer that silently relied on it (golden/QR tests without an override, E2E stacks running as Production, docker run docs) and give each its own throwaway key; add a fail-fast config validator that is skipped only for Development/Testing and is unit-tested with a stub IHostEnvironment.
- why: The M1 "committed key" golden test and the E2E stack (ASPNETCORE_ENVIRONMENT=Production) both read Jwt:Key from appsettings.json and would have broken or crashed once the key was removed.

## 2026-10-30 · IMMAN_HRIS M2 (backend-dotnet-dev)
- Applied to dotnet-backend-standards §6: matching dotnet-ef version; major-upgrade notes (Npgsql 10 DateOnly, NU1510, MSB3277 alignment — the last added by the lead after verifying).
### 2026-10-30 · backend-dotnet-dev · IMMAN_HRIS
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: When moving to Npgsql 10 / .NET 10, raw `ExecuteScalar` on a `date` column returns `DateOnly` (not `DateTime`); test helpers using `Convert.ChangeType` break. Also install a matching `dotnet-ef` 10 (`--tool-path` in temp) because the global one may be older, and drop the now-redundant `Microsoft.Extensions.Identity.Core` reference (NU1510).
- why: M2 upgrade failed 1 of 209 characterization tests only because of the DateOnly change; the global dotnet-ef was 9.0.7.

## 2026-10-30 · IMMAN_HRIS D1 (devops-engineer)
- Applied to devops-engineer: live action-version lookup without `gh` (How to work 2); `--reporter=list,html` for the CI Playwright artifact (Defaults/CI).
### 2026-10-30 · devops-engineer · IMMAN_HRIS
- target: .claude/agents/devops-engineer.md
- lesson: Without `gh`, look up latest action majors with `curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest`; and when the Playwright config only has the `list` reporter, pass `--reporter=list,html` in CI so a failure artifact actually exists.
- why: `gh` was not installed on this machine, and e2e/playwright.config.ts had `reporter: [['list']]`, so the planned playwright-report upload would have been empty.

## 2026-10-30 · IMMAN_HRIS M1 (qa-automation)
- Applied to qa-automation E2E rules: fake-camera QR scans (small QR inside the qrbox); `.npmrc` legacy-peer-deps for the npm `edgesOut` error. Heredoc half dropped (already a rule since 9010b51).


### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: Playwright fake-camera QR tests: html5-qrcode only decodes the centre `qrbox` (240 px) of the video, so render the QR in the .y4m small (cell <= 6 px); a full-frame QR silently never decodes. Generate the video in globalSetup after creating the employee, and launch Chromium with --use-fake-device-for-media-stream --use-file-for-fake-video-capture.
- why: the first scan test timed out at 30 s with no camera error until the QR was shrunk.

### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: On Windows with npm 10, `npm i -D jsdom` fails with "Cannot read properties of null (reading 'edgesOut')"; commit a `.npmrc` with `legacy-peer-deps=true` (and install `@testing-library/dom` explicitly) so local installs and `npm ci` agree. Also: a Bash tool call containing many heredocs with apostrophes can fail to parse and write nothing; use the Write tool for source files and check files exist.
- why: Vitest dependencies could not be installed until the flag was used; a multi-heredoc call wrote zero files.

## 2026-10-30 · IMMAN_HRIS (research-planner) · refactor planning
- Applied to research-planner Style: real-data refactor checks (startup Migrate + EF upgrade, secret-derived values with
  golden tests, free-plan Postgres) and the `.git/index` fallback when Glob/Grep fail.

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
