# E2E harness: isolated stack, viewport projects, layout helpers, axe gates, screenshot baseline/compare

Status: **implemented** — cafe-pos-system `d04812d`, IMMAN_HRIS `d4c2e28`, beth-online-shop `00a4328` (no-backend variant).

## Pieces
1. **Isolated compose stack** — own project name, container names, host ports and volume, so it never replaces the
   user's dev containers or data.
2. **Viewport projects** — one per target size; phone/tablet with `hasTouch: true, isMobile: true`; full suite on the
   primary project, `@layout|@a11y` (+ `@touch`) on the rest, run one project at a time.
3. **Layout helpers** — no horizontal scroll, shell fills viewport / body doesn't scroll, key controls fully in viewport
   (poll until animations settle), touch targets ≥ minimum, min font size.
4. **axe gates** — `@axe-core/playwright` with tags `wcag2a, wcag2aa, wcag21aa, wcag22aa`; allowlist entries name the
   rule and the milestone that fixes it; counts stored per milestone.
5. **Screenshot baseline + pixel compare** for "no visual change" refactors.
6. **No-backend harness** — build the SPA with `VITE_API_BASE_URL=/api/v1` into its own outDir, `vite preview`, fulfil
   `**/api/v1/**` with `context.route`, assert no un-mocked calls.
7. **Fake camera** for QR scanning (see below).

## Reference implementation
- Isolated stack: `cafe-pos-system/e2e/docker-compose.e2e-iso.yml` (`-p cafepos-e2e`, ports 15173/15080/15433),
  `IMMAN_HRIS/e2e/docker-compose.e2e.yml` (`name: hris-e2e`, `hris-e2e-db` on :15432, tmpfs data).
- Projects: `cafe-pos-system/e2e/playwright.config.ts` (tablet-landscape 1180×820 primary; large 1366×1024;
  small-landscape 1133×744; tablet-portrait 820×1180; phone 390×844), `IMMAN_HRIS/e2e/playwright.config.ts` +
  `IMMAN_HRIS/e2e/support/sizes.ts` (phone-small 375×667, phone 390×844, tablet 768×1024, tablet-landscape 1180×820, desktop 1280×800).
- Layout helpers: `cafe-pos-system/e2e/support/layout.ts`, `IMMAN_HRIS/e2e/support/layout.ts` (`expectNoHorizontalScroll`,
  `expectShellFillsViewport`, `expectInViewport`, `expectTouchTargets`), self-tests `IMMAN_HRIS/e2e/tests/layout-helpers.spec.ts`.
- axe: `IMMAN_HRIS/e2e/support/a11y.ts` (`AXE_TAGS`, `expectNoAxeViolations(page, allow)`), `IMMAN_HRIS/e2e/tests/a11y-baseline.spec.ts`,
  `cafe-pos-system/e2e/tests/a11y.spec.ts`.
- Screenshots: `cafe-pos-system/e2e/support/visual.ts` + `cafe-pos-system/e2e/tests/visual-baseline.spec.ts` + `cafe-pos-system/e2e/visual.mjs`;
  `IMMAN_HRIS/e2e/playwright.screenshots.config.ts`, `IMMAN_HRIS/e2e/shots/capture.spec.ts`, `IMMAN_HRIS/e2e/scripts/screenshots.mjs`,
  `IMMAN_HRIS/e2e/scripts/compare-screenshots.mjs` (pixelmatch), `IMMAN_HRIS/e2e/support/mockApi.ts`.
- No-backend harness: `beth-online-shop/e2e/scripts/serve-preview.mjs`, `beth-online-shop/e2e/playwright.config.ts`,
  `beth-online-shop/e2e/support/api.ts`, `beth-online-shop/e2e/support/checks.ts`, `beth-online-shop/e2e/tests/screens.spec.ts`.
- Re-runnable data: `cafe-pos-system/e2e/global-setup.ts` (restock), `IMMAN_HRIS/e2e/support/globalSetup.ts`.
- Fake camera: `IMMAN_HRIS/e2e/support/qrVideo.ts` (`writeQrY4m(file, text)`), `IMMAN_HRIS/e2e/tests/u5-scan.spec.ts`.
- Print: `IMMAN_HRIS/e2e/tests/print.spec.ts`; `window.print` stub in `cafe-pos-system/e2e/tests/payment.spec.ts`.

## Recipes
- **Deterministic screenshots:** fixed data via `context.route`, `animations: 'disabled'`, `caret: 'hide'`, fonts ready;
  prove a double run diffs at 0% before the change. For zero tolerance also `page.clock.setFixedTime`, stub
  `getUserMedia`, launch Chromium with `--disable-gpu --disable-lcd-text --font-render-hinting=none
  --force-color-profile=srgb --disable-gpu-compositing --disable-partial-raster` (never `--disable-threaded-compositing`:
  capture fails), and shoot until 3 consecutive frames are byte-identical.
- **Missing "before" axe count without a backend:** `git worktree add --detach $TEMP/<short> <sha>`, build its frontend,
  `vite preview --port <free> --strictPort`, run the mock-data spec through a throwaway config (no globalSetup,
  `baseURL: http://localhost:<port>` — preview binds localhost, not 127.0.0.1). Then stop the preview by PID,
  `git worktree remove`, delete the folder and the throwaway config.
- **Fake camera QR:** Chromium `--use-fake-device-for-media-stream --use-file-for-fake-video-capture=<file>.y4m`, video
  generated in global setup after the data exists. html5-qrcode decodes only the centre `qrbox` (~240px): draw the QR
  small (cell ≤ 6px). Every other spec on a camera page stubs `getUserMedia` to reject, or the fake QR scans by itself.

## Full-stack harness with a hosted-payment stub (beth `72e880b`)
- Reference: `beth-online-shop/e2e/playwright.fullstack.config.ts`, `beth-online-shop/e2e/support/stack/{globalSetup,payMongoStub,fixtures,db,shopApi}.ts`; run `npm run e2e:full:<project>`.
- Recipe: compose project with a tmpfs DB on its own port; SPA built with `VITE_API_BASE_URL=/api/v1` into
  `e2e/.stack/wwwroot` and served by the API (`Spa__RootPath`); `dotnet build -o e2e/.stack/api` then run the dll
  directly (no `dotnet run` child; dev `bin/` untouched); keep `ASPNETCORE_ENVIRONMENT=Development` for the seeder but
  override `ConnectionStrings__Default` by env (beats `appsettings.Development.json`, which points at the dev DB);
  `Storage__Local__RootPath` in the stack folder; raise every `RateLimiting__*` (all traffic is 127.0.0.1).
- Payment stub: plain `node:http` server started in globalSetup with `/__control/*` endpoints (list sessions, pay
  with/without webhook, replay the signed event N times, fail next create). It returns the real allowlisted host in
  `checkout_url`; specs answer that host per context with `context.route(host/**, r => r.fetch({url: STUB+path,
  maxRedirects: 0}).then(res => r.fulfill({response: res})))`, in the context fixture and every `newContext` helper.
- globalSetup that throws skips its teardown: wrap bring-up in try/catch that kills the API tree and the stub; run the
  "port busy" check before it so a second run never tears down the first.
- Kept-database hygiene: prefix created data (`E2E `), archive by prefix in before/afterAll, assert exact names (fuzzy
  `pg_trgm` search returns earlier runs' rows; newest-first paging hides seeded rows).
- Expiry without waiting: move the deadline in the test DB (`docker exec <e2e-db> psql … UPDATE … = now() - interval
  '1 minute'`).

## Gotchas
- Admin flows (beth `e2e/support/stack/{adminUi,orderFlows,db}.ts`, `e2e/full/q3-*.spec.ts`): set orders up via the
  API, do staff steps as clicks, re-read the customer page in a fresh empty context after each step. Different client IPs:
  `ForwardedHeaders__KnownProxies__0=127.0.0.1` in the stack env + `X-Forwarded-For` from the API helper.
- Phone nav helpers: wait for `.shell[data-typing]` to clear before branching on `isVisible()` after typing. Iterate with
  `E2E_KEEP_STACK=1 E2E_SKIP_BUILD=1`; check ports with `netstat -ano | grep LISTENING` (TIME_WAIT isn't busy).
- Radios whose checked state comes from the URL/async state: `.click()` then `expect(radio).toBeChecked()` (`.check()`
  reports "did not change its state"); keep `.check()` for plain form radios.
- Stopping a backgrounded `playwright test` by its CLI pid leaves `serve-preview.mjs`/`vite preview` holding the port
  ("already used" on every later run): kill the tree (`taskkill //F //T /PID <pid>`) or the port's listener.
- When the app allowlists redirect hosts (beth: `https://checkout.paymongo.com`), answer that host with `context.route`
  instead of a same-origin stub.
- Full-card/segmented radios: `getByRole('radio', { name }).check()`, never `getByText(label).click()` (the transparent
  input covers the text → 45 s "intercepts pointer events").
- Layered mocks: a `mockAdmin(context)` answering GETs from fixtures, recording POST bodies and ending in
  `route.fallback()` stacks on `mockApi`, so specs assert both the screen and the request a dialog sent
  (`beth-online-shop/e2e/support/admin.ts`). Keep fixtures realistic (e.g. ship dates never on Sunday).
- `expectBodyDoesNotScroll` catches `sr-only` elements escaping an unpositioned `overflow:auto` panel (page 7–11 px
  too tall); "intercepts pointer events" on `check()` means a positioned sibling paints over a full-card input.
- cafe-pos `npm run stack:up` (`docker-compose.e2e.yml` alone) **reuses the dev container names** — always add the
  `-iso` override with `-p cafepos-e2e`.
- Rebuild the frontend before shooting if the stack serves a prebuilt `dist`.
- `addInitScript` re-runs on reload: a session seeded that way returns after logout + reload; assert on storage.
- Projects with `grep` tags silently find no tests in untagged probe specs.
- Wait on content inside `getByRole('main')`, not nav text that may be hidden at that size.
