# Lessons log

Applied lessons, newest first. Each entry says where it was applied.

## 2026-10-30 · beth-online-shop B2a (backend-dotnet-dev)
- Applied to dotnet-backend-standards §7a (fail-closed body rate-limit keys; email links from configured base URL; sealed secrets in idempotent replays) and qa-automation How to work (own row per parallel request; mutation-check locks).
### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: Build links that go into emails (order links with tokens) from a configured public base URL, never from the request Host header, except in Development; without the setting, emit a relative link and log a warning.
- why: With the Host header an attacker can place an order with a victim's email and a forged Host, so the victim's email links (and bearer token) to the attacker's site.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/qa-automation.md
- lesson: A parallel test for a per-customer cap or per-key idempotency must give every request its own product/row, otherwise the shared row lock serialises the requests and the test passes without the advisory lock; mutation-check lock tests by removing the lock once and confirming the test fails.
- why: The COD per-phone cap test passed with the advisory lock removed until each request used a different product; only the mutation run showed it was not testing the lock.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: When a record stores a secret the client must get back on replay (idempotent checkout token), store it sealed (AES-GCM) under a key derived from the client's Idempotency-Key instead of in plain text; and a rate-limit key read from the body must fail closed (apply the strict limit) when the body cannot be read.
- why: The order access token is hashed at rest, so the stored idempotent response would otherwise have held it in clear for 24h; an oversize or chunked checkout body would otherwise have skipped the COD-only limit.

## 2026-10-30 · beth-online-shop B1 (backend-dotnet-dev)
- Applied to dotnet-backend-standards §6 (image header/EXIF orientation; EF project-last) and backend-dotnet-dev (dev seeder environment guard + test; no escape-bearing edits via one-liners).
### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: In EF Core repositories apply Where/OrderBy/Skip before the final Select when it builds a record through its constructor (`new Dto(...)`); filtering or ordering on such a projection (or a GroupBy over a join with Max) fails at runtime with "LINQ expression could not be translated". Project last, or use anonymous/member-initialised types when the caller still needs to filter.
- why: B1 category lists, the public category query and the sitemap category dates all returned 500 on first run until the filter moved before the projection.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: An image upload pipeline that re-encodes to strip EXIF must apply the EXIF orientation to the pixels first (SkiaSharp's SKCodec/SKBitmap.Decode do not), and read the header dimensions (SKCodec.Info) to refuse oversized images before decoding. Test with a JPEG that has an injected APP1 Orientation tag and a marker string.
- why: Dropping the tag without rotating would have saved every phone portrait photo sideways; the orientation tests (6, 8, 3) and the marked-corner pixel check caught the matrix maths.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/backend-dotnet-dev.md
- lesson: A dev-data seeder must check `IHostEnvironment.IsDevelopment()` itself, not only a `SeedDevData` config switch, and have a test that boots a Production-environment host with the switch on and asserts no users or catalog rows exist (verify the test fails with the guard removed).
- why: The B0 review found known passwords would seed in production on a wrong env var; the guard plus a mutation check (guard disabled -> test fails) proved the test is real.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/backend-dotnet-dev.md
- lesson: Do not make C# edits that contain backslash escapes ("\n", "\"") through a Python or sed one-liner in Bash: the escaping is consumed once and the file gets literal line breaks inside string constants. Use the Edit tool for those lines.
- why: A python replace of `"\n"` wrote a real newline into a const string and cost three build-fix rounds.

## 2026-10-30 · beth-online-shop F0 (frontend-react-dev)
- Applied to react-frontend-standards §5 (non-empty layer blocks in eager CSS; flex-column shell; sticky phone action bar; field errors outside the label via aria-describedby instead of regex label queries) and frontend-react-dev (backend-free screenshot harness; run Prettier from frontend/).
### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: In the CSS layer rule, keep at least one non-empty `@layer features` block in the eagerly loaded stylesheet (for example shared prose/empty-state styles), not only in lazy route chunks. Lightningcss drops the leading `@layer a, b, c` statement in minified builds, so a layer that first appears in a lazy chunk lands above `utilities`.
- why: In the Beth F0 build the minified main CSS began with `@layer reset{...}` and had no `features` layer, so the admin chunk's `features` styles would have outranked `utilities`; adding `shared.css` (`@layer features`) before `utilities.css` restored the order.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: Build the app shell as a flex column (header `flex: none`, scroll area `flex: 1 1 0; min-height: 0`), not a CSS grid with a fixed row list, when an optional child (demo banner) may be absent.
- why: A 3-row grid `auto auto minmax(0,1fr)` put the scroll area in an `auto` row when the banner was missing, leaving a blank strip under the footer; only the opened screenshot showed it, all tests and axe passed.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/agents/frontend-react-dev.md
- lesson: When a screenshot harness has no backend, build the frontend with `VITE_API_BASE_URL=/api/v1` into a separate outDir and fulfil `**/api/v1/**` with `context.route`; collect un-mocked calls and assert the list is empty. Run `prettier --write` from the frontend folder (or pass its ignore file), because running it from `e2e/` reformatted the generated `schema.d.ts`.
- why: Same-origin routing avoided CORS preflights for Authorization/JSON requests; the e2e `.prettierignore` did not list `schema.d.ts`, so a `prettier --write ../frontend/src` rewrote it.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: Field errors rendered inside the `<label>` change the control's accessible name; tests and E2E should query labels with a `^Label` regex, and a long-form phone page needs a sticky primary-action bar so the button stays inside the 375x667 viewport.
- why: `getByLabelText('Password')` failed after validation added "Password is required" inside the label, and the Change password button sat 55px below the 667px fold until it was made sticky.

## 2026-10-30 · beth-online-shop B0 (backend-dotnet-dev)
- Applied to dotnet-backend-standards OpenAPI section (string enums via ConfigureHttpJsonOptions) and backend-dotnet-dev Constraints (no heredocs, incl. edit scripts).
### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: When controllers use AddJsonOptions(JsonStringEnumConverter), also call services.ConfigureHttpJsonOptions(o => o.SerializerOptions.Converters.Add(new JsonStringEnumConverter())), and check enum schemas in the regenerated openapi/v1.json: the OpenAPI generator reads the minimal-API options, not the MVC ones.
- why: The B0 snapshot published DayOfWeek as {"type":"integer"} while the API serialised "Monday", so generated frontend types would have been wrong; found only by reading the snapshot.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/backend-dotnet-dev.md
- lesson: Never feed multi-line code to Bash with heredocs when it contains single quotes, including `python - <<PY` edit scripts and C# test files: the whole command fails or truncates. Write the script/file with the Write tool (scratchpad for scripts) and run it.
- why: Three bash calls in this run failed with "unexpected EOF" and one silently truncated PhoneNumber.cs mid-line; only the Write tool was reliable.

## 2026-10-30 · beth-online-shop plan (research-planner, reported in final message)
- Applied to research-planner "What to research" (free-plan SMTP/disk limits; wallet-app return page from URL token; llms.txt for blank provider docs) and dotnet-backend-standards §6 (check licences; SkiaSharp over ImageSharp).
- Free-plan limits: Render free blocks SMTP 25/465/587 since Sep 2025 and has no persistent disk; SMTP or local-disk images pass local tests and fail after deploy.
- Wallet redirects: in-app browsers send the payment return to a different browser with empty localStorage.
- ImageSharp 3+ Split License; v4 needs a licence file at build time. Default to SkiaSharp.
- PayMongo docs fetch blank; use https://docs.paymongo.com/llms.txt and the .md URLs it lists.

## 2026-10-30 · IMMAN_HRIS U3 QA (qa-automation)
- Merged into qa-automation E2E rules (axe "before" counts recipe), plus a lead addition: stop the preview by PID and delete the worktree folder afterwards (the agent left a vite preview running in $TEMP/h11).
### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: A "before" axe/screenshot count for an old commit needs no backend: `git worktree add --detach $TEMP/<short> <sha>`, `npm ci --legacy-peer-deps && npm run build` in its frontend, `npx vite preview --port <free> --strictPort`, and run the mock-API spec through a throwaway Playwright config (no globalSetup, `baseURL: http://localhost:<port>` — vite preview binds localhost/IPv6, 127.0.0.1 is refused). Delete the throwaway config afterwards.
- why: U3 before-counts for five projects took about 4 minutes this way without touching the E2E stack or the dev stack.

## 2026-10-30 · IMMAN_HRIS U5 QA (qa-automation)
- Applied to qa-automation E2E rules: @touch tag in touch project grep, reset one-shot actions via admin API, axe "before" counts via git worktree, stub getUserMedia on non-camera specs; Constraints: stop servers by port/PID, not command-line pattern.
### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: Every viewport project below the desktop breakpoint must set `hasTouch: true, isMobile: true` so `(pointer: coarse)` code paths (PIN keypad, full-screen overlays, 48px sizes) are exercised; keep one mouse desktop project. Tag touch-only specs `@touch` and add the tag to the non-desktop `grep`.
- why: only tablet-landscape was touch, so the phone keypad and kiosk overlay were never run at phone sizes.

### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: A fake-camera scan on a shared E2E database is one-shot per day: before each such test delete the scan employee's attendance through the admin API (GET then DELETE /admin/attendance/{id}) instead of relying on a fresh DB, so the same scan runs on several projects and re-runs.
- why: running the scan smoke on tablet-landscape and desktop in one invocation would have hit "already timed in".

### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: To get an axe "before" count for a finished milestone, build the old commit in a throwaway `git worktree` under a short temp path, serve it with `vite preview` and run the axe spec against fixed `context.route` data. Do not kill processes by command-line pattern (`*port*`): it also kills your own shell; kill by listening port or PID.
- why: the baseline counts were never stored; a pattern kill of the preview server terminated the agent's own shell.

### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: UI specs on a page that uses the camera (scan kiosk) must stub `getUserMedia` to reject (init script) unless the test is the camera test; with the fake video running, the QR scans by itself, races overlay assertions, and the decode load makes taps slow (tests grew from 1s to 50s and flaked at the 60s timeout).
- why: U5 kiosk tests failed intermittently on phone/tablet until the camera was stubbed off; afterwards each ran in 1-2s.

## 2026-10-30 · IMMAN_HRIS U5 (frontend-react-dev)
- Applied to react-frontend-standards §3 Auth (re-auth prompts bypass the shared 401 handler) and qa-automation E2E rules (phone/tablet projects get hasTouch + isMobile) instead of the temporary-config workaround.
### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: A "check credentials" call made with the shared API client signs the user out on a wrong password if that client has a global 401 handler; use a bare HTTP call (or a client without the interceptor) for re-authentication prompts such as exiting kiosk mode.
- why: the planned kiosk exit re-used the admin login endpoint through apiClient, whose 401 interceptor clears the stored session and redirects to /login; a Vitest case (wrong password keeps kiosk and session) caught the design before it shipped.

### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/agents/frontend-react-dev.md
- lesson: Playwright size projects without hasTouch/isMobile report (pointer: fine), so touch-only UI (PIN keypad, inputMode none) never shows in them; to review it, capture with a temporary untracked config that adds hasTouch and isMobile, and delete it afterwards.
- why: the U5 phone and phone-small screenshots showed no keypad until a temporary touch-emulated spec revealed that Sign in was clipped by 26px at 375x667.

## 2026-10-30 · IMMAN_HRIS U2 QA (qa-automation)
- Applied to qa-automation E2E rules (stub bullet): init scripts re-seed sessions on reload; tag probe specs when projects grep by tag.
### 2026-10-30 · qa-automation · IMMAN_HRIS
- target: .claude/agents/qa-automation.md
- lesson: In projects that filter non-primary sizes with `grep: /@layout|@a11y/`, put `@layout` in the title of throwaway probe specs too, or Playwright reports "No tests found" and the probe silently prints nothing. When mocking auth with `addInitScript`, a post-logout reload re-seeds the session, so assert on localStorage instead of reloading.
- why: U2 touch-target probe printed nothing on phone/tablet until renamed; the first logout tests failed because the init script restored the token.

## 2026-10-30 · IMMAN_HRIS U2 (frontend-react-dev)
- Applied to frontend-react-dev How to work 5: rebuild before screenshots when the E2E stack serves a prebuilt dist. Dropped the grid-cell z-index note (general CSS, not a workspace rule).
### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/agents/frontend-react-dev.md
- lesson: Playwright screenshot/E2E runs serve a prebuilt `frontend/dist` and only rebuild with `E2E_REBUILD_FRONTEND=1`; set it (or run `npm run build`) after every CSS/TSX change before capturing screenshots.
- why: the first u2 screenshots were taken from a stale dist, so a fix (z-index on the phone Log out button) looked like it had not worked and cost two 2.5 minute screenshot runs.

### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: When one grid cell holds two items (phone app bar plus a Log out button that is a sibling in the same cell), give the overlaid item `position: relative; z-index: 1`, because the later item's background paints over it.
- why: the phone Log out button was fully hidden behind the app bar background and no jsdom test could see it; only a screenshot did.

## 2026-10-30 · IMMAN_HRIS F0/U1 (frontend-react-dev)
- Applied to react-frontend-standards §5 CSS structure (layer split winner flips; lightningcss drops the @layer statement) and frontend-react-dev Constraints (no heredocs; Prettier endOfLine auto with autocrlf).
### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: When splitting a flat stylesheet into `@layer` files, assign layers by original file position first, then check every rule that moves to a higher layer than a rule that originally came after it (a postcss script comparing property overlap plus class co-occurrence in the TSX finds them). Such pairs silently flip the winner; the one found here was `.btn-large` placed before `.btn`, so `.btn` was winning and `.btn-large` had no effect. Keep such a rule ahead of its sibling in the same layer to stay pixel-identical.
- why: IMMAN_HRIS U1: layering `.btn-large` (portal feature) above `.btn` (components) would have changed Time In/Out sizing, which only a real-browser screenshot diff would show.

### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: Production CSS minified by lightningcss (Vite 8) drops the leading `@layer a, b, c;` statement when the layers already first appear in that order, and the order survives only by first appearance. Check `vite build --minify false` to confirm the statement is emitted, and do not rely on the statement alone when a later file might introduce a layer out of order.
- why: IMMAN_HRIS U1: `dist/assets/index-*.css` began with `@layer reset{` while the source file began with the order statement.

### 2026-10-30 · frontend-react-dev · IMMAN_HRIS
- target: .claude/agents/frontend-react-dev.md
- lesson: On Windows with `core.autocrlf=true`, set `"endOfLine": "auto"` in `.prettierrc` before running `prettier --write` over an existing repo, and write heredocs to files with the Write tool, not bash (quoted `'E'` heredocs with apostrophes in the body failed to parse and ran nothing).
- why: IMMAN_HRIS F0: Prettier's default `lf` would fail `format:check` on fresh CRLF checkouts; a bash heredoc containing an apostrophe aborted the whole command.

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
