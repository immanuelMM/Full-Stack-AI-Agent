# Lessons log

Applied lessons, newest first. Each entry says where it was applied.

## 2026-10-31 · beth-online-shop frontend review fixes (frontend-react-dev)
- Wiki: e2e-playwright-harness gotchas (kill the preview process tree; route allowlisted redirect hosts). The general "stop servers by port/PID" rule already exists in qa-automation.
### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/e2e-playwright-harness.md
- lesson: Killing a backgrounded `playwright test` run (taskkill on the CLI pid) leaves its `serve-preview.mjs` and `vite preview` children holding the preview port, so every later run fails with "already used". Kill the whole tree (`taskkill //F //T`) or the listener on the port before re-running. Also, when the app restricts redirects (e.g. only `https://checkout.paymongo.com`), the harness must answer that host with `context.route` instead of a same-origin stub.
- why: after stopping a run, four chained projects all failed instantly on port 4175; and the same-origin `/pay-stub` URL broke two checkout specs once `redirectTo` got an allowlist.

## 2026-10-31 · beth-online-shop review fixes (backend-dotnet-dev)
- Wiki: jwt-refresh-auth (per-IP lockout, active-user cache), rate-limiting-forwarded-headers (test IP filter, size-limit test), cash-on-delivery (abuse caps), same-origin-single-image-deploy (security headers). Standards: dotnet-backend-standards §6 (in-place data migrations, HasData defaults, optional PUT fields) and §7a (OnCompleted lookups, test IP filter). Dropped: rebuild-after-migration (already a rule).
### 2026-10-31 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/jwt-refresh-auth.md
- lesson: Identity's per-account lockout lets anyone who knows a public staff email lock that person out (the check runs before the password). Count failures per (account, client IP) in a small table with an atomic `INSERT ... ON CONFLICT DO UPDATE` and a second conditional UPDATE that sets `LockedUntil`; check lock for that pair only, delete the row on success, purge old rows in the sweeper, and run a dummy hash verify for unknown accounts. Reference: beth `IdentityService.RecordAccessFailedAsync`/`IsLockedOutAsync`, `LoginFailures`, tests `AuthTests.An_attacker_locks_only_their_own_address...`. Also reject access tokens of disabled users in `JwtBearerEvents.OnTokenValidated` through a 30 s cache that user-disable invalidates (beth `ActiveUserCache`); this replaces the "deactivated user keeps access until expiry" trade-off.
- why: the security review showed 5 bad tries from anywhere locked the Owner for 5 minutes, repeatedly.

### 2026-10-31 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/rate-limiting-forwarded-headers.md
- lesson: Test hosts have no socket (RemoteIpAddress is null), so per-IP behaviour cannot be tested; add an `IStartupFilter` that sets `RemoteIpAddress` from a test header (beth `TestClientIpFilter`, `client.FromIp("203.0.113.5")`). Also: a rate-limit partition that depends on a parsed body must fail closed (fixed shared bucket) when the body is chunked, too big or malformed, otherwise the budget is skipped; and log a startup warning (not a failure) outside Development when KnownProxies/KnownNetworks are empty. The in-memory TestServer does not enforce `[RequestSizeLimit]`, so assert the attribute by reflection (its private `_bytes` field).
- why: the per-email lookup limiter silently had no partition for chunked bodies; the size-limit test passed 202 for a 5 KB body.

### 2026-10-31 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/cash-on-delivery.md
- lesson: COD costs nothing to place and holds stock, so cap it: a shop-wide count of unconfirmed COD orders (advisory lock "cod:unconfirmed-cap" in checkout so the last slot goes to one buyer) and a per-variant share of on-hand (min 1 unit), both as quote reasons; store the client IP on the order (zone id stripped, cleared by the retention job) and give staff a bulk "cancel unconfirmed COD from the same IP/contact" action that cancels each order in its own transaction under its order lock. A late COD confirmation or late payment must re-check made-to-order daily capacity for the day the order was placed (lapsed orders are excluded from the count, so the slot may be gone), not only stock. Existing shared-fixture tests place many COD orders: lift the caps in the shared test host and give cap tests their own host (beth `ApiFactory.CreateHost`, `KeepCodCapsKey`).
- why: the security review found fake COD orders could hold stock indefinitely; adding the caps broke 9 unrelated shared-host tests until the fixture lifted them.

### 2026-10-31 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/backend-dotnet-dev.md
- lesson: (1) Order-lookup style "email me my link" endpoints: do one light read in the request and send the link in `Response.OnCompleted`, so match and miss answer alike; tests then poll (beth `Eventually.WaitAsync`). (2) To hash a stored key in place, write the migration SQL (`encode(sha256(convert_to("Key",'UTF8')),'hex')`) instead of dropping rows, and pin it against the C# hash in a test. (3) A new NOT NULL int settings column needs its default in `HasData` (EF emits an UpdateData for the seeded row); make the new PUT fields optional so the existing frontend keeps working until it sends them. (4) After adding a migration run `dotnet build` before `dotnet test --no-build`, otherwise every integration test fails on the missing column.
- why: each of these cost a failed run or would have broken a live row or client this session.

### 2026-10-31 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/same-origin-single-image-deploy.md
- lesson: The SPA fallback and static files should carry `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff` and a CSP built from config (img-src adds the R2 public origin); the Vite build has no inline scripts or styles (React's `style` prop is CSSOM, allowed by `style-src 'self'`), so no `'unsafe-inline'` was needed. Reference: beth `SpaSecurityHeaders.cs`.
- why: security review L4; the headers are covered by `SpaHostingTests`.

## 2026-10-31 · beth-online-shop security + code review (lead)
- dotnet-backend-standards §7a: lockout per (account, IP); dummy hash for unknown emails; reject disabled users' tokens; RequestSizeLimit for body-derived keys; hashed idempotency keys; SPA security headers + no-proxy warning; shop-wide abuse caps. react-frontend-standards §3: provider-only https redirects; timestamps in app time zone. Source: beth security review M1–M3, L1–L5 and code review findings 4, 8.

## 2026-10-31 · beth-online-shop F3 (frontend-react-dev)
- Standards: react-frontend-standards §3 (array query serializer) and §5 (namespace classes per bundle). Wiki: touch-ui-shell, e2e-playwright-harness (radio check, layered mocks, realistic fixtures), windows-dev-machine (cp1252), apps/beth-online-shop (back office, status).
### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md
- lesson: A custom openapi-fetch `querySerializer` must repeat the key for array values (`Status=A&Status=B`); `String(array)` sends `Status=A,B`, which ASP.NET binds as one invalid enum. Unit-test the serializer with an array.
- why: The F0 serializer (copied from cafe-pos) comma-joined arrays; the repeatable `Status` filter of `GET /admin/orders` only worked after the fix, caught by an RTL test asserting `getAll('Status')`.

### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/touch-ui-shell.md
- lesson: Before naming a back-office class, grep every stylesheet of the other bundle: storefront `catalog.css` already defined `.chips`, `.chip`, `.link-btn` and `orders.css` `.facts`, and same-layer rules from two bundles merge silently (admin chips wrapped instead of scrolling, in a screenshot only). Gotcha line "beth's admin layout.css still uses the instant form" is fixed: AdminShell now sets `data-typing` from focus/blur handlers (250 ms grace), same as StoreShell.
- why: F3 admin tabs rendered as wrapped, oversized pills until renamed to `.view-tab(s)`; no unit test could see it.

### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/e2e-playwright-harness.md
- lesson: For segmented/full-card radios click the real input with `getByRole('radio', { name }).check()`, never `getByText(label).click()` (the transparent input covers the text and Playwright waits 45 s for "intercepts pointer events"). A `mockAdmin(context)` that answers GETs from fixtures, records POST bodies and ends with `route.fallback()` layers cleanly on top of `mockApi`, so specs can assert both screens and the request a dialog sends.
- why: `f3-inventory-adjust-correction` hung until switched to `.check()`; the ship dialog and keypad specs assert the recorded POST bodies (`beth-online-shop/e2e/support/admin.ts`).

### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/platforms/windows-dev-machine.md
- lesson: Python run from Git Bash on Windows reads and writes files as cp1252: a script that edits sources containing `₱` or other non-ASCII crashes with UnicodeDecodeError halfway, leaving some files edited. Use `io.open(path, encoding='utf-8', newline='')`. A bash heredoc containing an apostrophe can also fail to parse as a whole and silently run nothing: write files with the Write tool.
- why: Two multi-file refactor scripts in F3 failed mid-way (cp1252 decode of `₱`; an unterminated-quote heredoc that created no files).

### 2026-10-31 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/apps/beth-online-shop.md
- lesson: F3 back office reference: pages in `frontend/src/features/{dashboard,adminOrders,inventory,users,codBlocks,settings}`; shared back-office CSS in `features/admin/admin.css`. The order detail renders buttons only from `allowedActions` (steps in a sticky `action-bar`, exceptions under "Other actions") and handles every 409 (`InvalidTransition`, `StockUnavailable`, `Conflict`) by closing the dialog, showing the API message and refetching the order. The orders list keeps all filters in the URL (`orderFilters.ts`), so dashboard tiles are plain links; filters are inline from 1100 px and a Modal sheet below. Settings tabs send the whole loaded `ShopSettings` with the tab's fields changed and remount on `version`.
- why: Summary for the app page so the next agent (Q3, docs) does not re-derive it.

## 2026-10-31 · beth-online-shop B3 verification (lead)
- Applied to qa-automation How to work: date-dependent tests share a fake clock with the server. Found by the lead: the dashboard test failed in a run that crossed Manila midnight; the agent had called it load.

## 2026-10-30 · beth-online-shop B3 verification (lead)
- Applied to dotnet-backend-standards §6: timestamp-ordered lists need a stable tie-breaker. Found by the lead's re-run: Delivered and Completed shared a timestamp and the timeline came back reversed (failed 3/3 alone though the agent reported green).

## 2026-10-30 · beth-online-shop B3 (backend-dotnet-dev)
- Wiki: cash-on-delivery (admin step runner, state table, status), made-to-order (back-office views, status), jwt-refresh-auth (admin reset without token providers). Standards: qa-automation (xmin hides missing locks; differing-outcome races), dotnet-backend-standards §6 (rebuild after migration). Dropped: CA1826 / expression-tree operator notes (compiler reports them).
### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/cash-on-delivery.md
- lesson: Admin order steps (confirm, ship, cash collected, return, cancel, ship date) share one runner: begin transaction, `LockOrderAsync(number)`, `ClearTracking`, reload the order, run the step (variant rows `FOR UPDATE` in id order when it touches stock), save, commit, then reload for the response; a failed step returns an Error and the transaction is disposed uncommitted. Put the state machine in one table (`OrderStateMachine.IsAllowed`) that `Order.Transition` enforces for every caller (payment, sweeper, admin) and test it exhaustively (every from/to pair per payment method and fulfilment). A COD order's stock leaves the shelf when it ships (consume its held reservations then); a late confirm re-checks stock because the hold lapsed; cancel restocks only reservations already consumed. Reference: `beth-online-shop/backend/src/BethShop.Application/Features/AdminOrders/AdminOrderService.cs`, `.../Domain/Orders/OrderStateMachine.cs`, `.../tests/BethShop.Domain.Tests/OrderStateMachineTests.cs`.
- why: B3 built these with 88 new tests; the exhaustive table test and one runner kept every step consistent and the races tests green.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/agents/qa-automation.md
- lesson: When you mutation-check a lock, `xmin` (the concurrency token backstop) hides the missing lock in "all requests answer 200" tests: removing the order lock still passed cancel-vs-webhook, ship x8 and cash x2. Tests that caught it were races whose two outcomes differ in stock or status (confirm vs sweeper, cancel vs sweeper, two confirms, parallel stock corrections that must never exceed on-hand). Design a race so one interleaving gives a different final state, assert each outcome's full invariant (status, reserved, on hand, movements, emails) and run it over ~10 orders at once.
- why: removing `LockOrderAsync` from the admin runner failed 3 of 7 race tests; removing the variant `FOR UPDATE` failed only the parallel-corrections test.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/jwt-refresh-auth.md
- lesson: An administrator password reset cannot use `UserManager.GeneratePasswordResetTokenAsync` when Identity was added with `AddIdentityCore`/`AddIdentityApiEndpoints`-style setup and no token providers (it throws, a 500). Validate with `users.PasswordValidators`, set `entity.PasswordHash = users.PasswordHasher.HashPassword(...)`, `UpdateAsync`, then revoke all refresh tokens and clear the lockout (`AccessFailedCount`, `LockoutEnd`). Disabling a user: set `Active = false` and revoke refresh tokens; refuse to disable an Owner (and yourself) so the shop cannot lock itself out.
- why: the first reset test returned 500 until the token step was replaced (`IdentityService.ResetPasswordAsync` in beth-online-shop).

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: After adding an EF migration, never run `dotnet test --no-build` on the integration project from a stale build: the host sees a model with pending changes ("PendingModelChangesWarning") and every test fails at startup. Rebuild first. Also: EF expression trees cannot contain `^`/range operators (compute the string outside the query), and in this solution CA1826 makes `.First()`/`.Last()` on a list a build error in tests (use `[0]`/`[^1]`).
- why: 303 of 352 tests failed with that warning after the AdminOrders migration until the project was rebuilt.

### 2026-10-30 · backend-dotnet-dev · beth-online-shop
- target: .claude/wiki/features/made-to-order.md
- lesson: Back-office views for made-to-order orders need no new tables: `HasMadeToOrder` + `EstimatedShipDate` on the order give "overdue" (Confirmed/Preparing and date before today, Manila) and "due in 3 days" counts; the sweeper raises a "Ship date passed" flag (a segment of `NeedsAttentionReason`) that clears on ship, cancel or moving the date and cannot be cleared by hand while true (otherwise the sweeper re-raises it every minute). A ship-date change needs a reason, a date not in the past, and emails the customer.
- why: implemented and tested in B3 (`OrderExpiryService.FlagOverdueShipDatesAsync`, `AdminOrderService.ChangeShipDateAsync`).

## 2026-10-30 · beth-online-shop F2 (frontend-react-dev)
- Standards: react-frontend-standards §3 (generate from committed snapshot) and §5 (tab bar back ~250 ms after blur; positioned scroll containers); frontend-react-dev (lazy-route CSS chunks). Wiki: touch-ui-shell, e2e-playwright-harness, idempotent-checkout-reservations (client key hook), openapi-contract, apps/beth-online-shop (PSGC data, status).
### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/touch-ui-shell.md
- lesson: A phone tab bar that hides on text-field focus (`:has(input:focus)`) must come back a moment AFTER the blur (about 250 ms, a data attribute set by focus/blur handlers on the shell), not at it. Tapping a sticky Pay button or a radio blurs the field at mousedown, the bar pops back, the layout shifts under the finger and the click lands on the page, so the first tap is lost. The admin shell `layout.css` still uses the instant `:has(:focus)` form.
- why: Playwright `click()` on the checkout Pay button after typing did nothing; a document click listener showed the target was `div.store`, not the button.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/e2e-playwright-harness.md
- lesson: Two checks that caught real CSS bugs: (1) an `.sr-only` (absolute) element inside an `overflow: auto` shell panel that has no positioned ancestor escapes the clipping and makes the document 7-11 px taller than the viewport, so give the scroll container `position: relative`; (2) a full-card radio (`input` absolutely covering a label) must not have a positioned sibling face painted over it, or Playwright reports "intercepts pointer events"; put the decorative dot on the wrapper's `::before` with `pointer-events: none` and leave the face unpositioned.
- why: `expectBodyDoesNotScroll` failed at 375x667 on checkout only; `check()` timed out on the pickup radio at 390x844.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/idempotent-checkout-reservations.md
- lesson: Client side: keep one Idempotency-Key per request body (hook `frontend/src/features/checkout/useIdempotencyKey.ts`): reuse it on retry after a timeout/5xx, and make a new one when the body changes (an edited field, or the `expectedTotal` after a 409 PriceChanged), because the server answers 422 IdempotencyKeyReused for the same key with a different body. Mutation-checked by RTL test "reuses the Idempotency-Key when the same request is retried".
- why: the 409 PriceChanged flow changes `expectedTotal`, so reusing the old key there would have turned every refreshed quote into a 422.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/apps/beth-online-shop.md
- lesson: PSGC data for address selects: `frontend/scripts/build-psgc.mjs` builds `src/features/checkout/psgc.json` (25 kB, 82 provinces, 1,634 cities) from `https://psgc.gitlab.io/api/{provinces,cities-municipalities}.json`. The API's 10-digit code is `psgc10DigitCode` (9-digit `code` differs); Metro Manila has no province (cities carry a `districtCode`), so it is listed under the NCR code `1300000000` which the default zone includes; City of Isabela and City of Cotabato have no province and map to Basilan and Maguindanao. Checkout is a lazy route so the JSON stays out of the main bundle; the province select lists only provinces found in `/shipping/zones`.
- why: needed real codes that match the seeded zones; the first guess (province-level code only) would have missed NCR.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/wiki/features/openapi-contract.md
- lesson: When another agent has an uncommitted `openapi/v1.json` in the shared working copy, generate the frontend types from the committed snapshot (`git show HEAD:backend/openapi/v1.json > $TEMP/v1.json` then `openapi-typescript $TEMP/v1.json -o src/api/schema.d.ts`), not from the working file, or the frontend commit carries someone else's in-progress types.
- why: mid-run the backend working copy gained the B3 admin endpoints (+4,000 lines) while B2b's committed snapshot only added `/pay`.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/agents/frontend-react-dev.md
- lesson: Feature CSS imported by a lazy route is a separate chunk: classes shared with a non-lazy page (here the order page reusing checkout line and summary rules) must live in a stylesheet the other page imports too. Vitest runs with `css: false`, so only a screenshot of the page opened directly (empty cache, no prior visit to the lazy route) shows it.
- why: caught while reviewing the build output (`CheckoutPage-*.css` chunk) before the order page screenshots; moved the shared rules to `cart.css`.

## 2026-10-30 · beth-online-shop B2b (backend-dotnet-dev)
- Wiki: platforms/paymongo.md rewritten (confirmed vs assumed, reference files, FakePayMongo test double — placed there instead of same-origin deploy); features/idempotent-checkout-reservations.md gained the payment-apply recipe. Standards: dotnet-backend-standards §7a (required settings in test factory; layered guards tested alone; xmin lock via SELECT 1 FOR UPDATE). Dropped: CA1068 and internal typed-client notes (compiler tells you).
### 2026-10-30 · backend-dotnet-dev (beth-b2b) · beth-online-shop
- target: .claude/wiki/platforms/paymongo.md
- lesson: Confirmed from the docs (2026-10-30, llms.txt .md pages): signature header `t=,te=,li=`, string to sign `"{t}.{raw body}"`, HMAC-SHA256 hex, `te` test / `li` live, timestamp check optional (retries replay the old timestamp, so skip it); amounts are integer centavos (examples 10000 = P100, 49900 with fee 760 = payment 50660); create = `POST /v2/checkout_sessions` (Basic auth, `checkout_url` in `data.attributes`), retrieve = `GET /v1/checkout_sessions/{id}` (`attributes.status` active|expired, `payments[]` with `attributes.status=paid`, `amount`, `currency`, `paid_at`, `source.type`), expire = `POST /v1/checkout_sessions/{id}/expire` (400 if already expired / paid / ongoing); sessions NEVER expire on their own and PayMongo sends no event on expiry, so the shop must call expire; payments on an expired session are rejected by PayMongo; `payment_method_types` seen: gcash, paymaya, grab_pay, card, qrph, atome; webhook retries are 12 (the "3" is stale); event envelope is `data.id (evt_), data.attributes.{type,livemode,data}` but the Hosted Checkout page shows a flatter `send.webhook` shape without an event id. Still assumed: retrieve/expire on v2-created sessions, `paid_at` present in the webhook, hex case, `?t=` in success_url, line-name length.
- why: read all of it from docs.paymongo.com for B2b; recorded in beth backend/README.md ("confirmed vs assumed"); no test keys, so nothing was called live.

### 2026-10-30 · backend-dotnet-dev (beth-b2b) · beth-online-shop
- target: .claude/wiki/features/idempotent-checkout-reservations.md
- lesson: Payment-apply recipe (beth `PaymentApplier`/`PaymentService`): one code path for webhook, reconcile-on-read and sweeper; inside one transaction take `pg_advisory_xact_lock('order:'||number)`, then `ChangeTracker.Clear()` and reload the order (EF identity resolution keeps a stale tracked copy otherwise), lock variants FOR UPDATE in id order, consume reservations + stock movements, set Confirmed/Paid, queue the email, save; keep the `xmin` token as a backstop and let the webhook answer 503 on a conflict so the provider retries. Insert the webhook event id (unique key) first in the same transaction so a concurrent duplicate waits and then hits the violation. Paid-after-expiry: re-take stock only if `OnHand - heldByOthers >= qty`, else Confirmed + NeedsAttention and move nothing. Sweep each overdue order in its own transaction under the same lock.
- why: 8 parallel webhooks and 12 webhook-vs-reconcile and webhook-vs-sweeper races stay consistent; removing the order lock made 1 to 7 deliveries answer 503 in three tests.

### 2026-10-30 · backend-dotnet-dev (beth-online-shop)
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: Layered guards hide a removed guard: when a state check, a unique event row and an advisory lock all protect the same operation, deleting one lock leaves the test green. Design each concurrency test so one guard is the only defence (distinct event ids for the lock, assert the dedup row count for the unique insert, assert every response is 200 so an `xmin` backstop conflict shows as a 503), then mutation-check by commenting the guard out and seeing the test fail. Also: adding a REQUIRED production setting (ValidateOnStart) breaks every existing test that boots a non-Development host, so add the new keys to the test factory's base config (https base URL in non-Development) in the same change.
- why: removing the order lock alone still left state consistent (xmin backstop), only the 200-assertions failed; adding PayMongo keys as required broke the 4 existing Production/Staging seed and R2 tests until the factory supplied them.

### 2026-10-30 · backend-dotnet-dev (beth-b2b) · beth-online-shop
- target: .claude/wiki/features/same-origin-single-image-deploy.md
- lesson: Reusable test double: `FakePayMongo` (WireMock.Net 2.21 callbacks backed by a session dictionary: idempotent create by Idempotency-Key, retrieve with a paid payment, expire that answers 400 for expired/paid, failure switches, a signed `PaidWebhook` builder) plus a `PayMongoHost` xunit collection fixture with its own fake and factory, in `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/FakePayMongo.cs` and `PaymentTestSupport.cs`. Copy for any provider with hosted sessions; WireMock responses are `ResponseMessage` with `BodyData`, request headers are an `IDictionary<string, WireMockList<string>>` (look them up case-insensitively); raw-string JSON with `}}` needs `$$"""` or use JsonObject.
- why: built for B2b; 52 payment tests run against it in about 25 s without touching the real API.

### 2026-10-30 · backend-dotnet-dev (beth-b2b) · beth-online-shop
- target: .claude/skills/dotnet-backend-standards/SKILL.md
- lesson: Small .NET gotchas hit while building a typed HttpClient and EF raw SQL: CA1068 requires CancellationToken as the LAST parameter (also on private overloads with a bool); `FromSql("SELECT * ...")` does not return the `xmin` system column, so entities with an xmin concurrency token must be locked with a separate `SELECT 1 ... FOR UPDATE` and then loaded normally; a typed `AddHttpClient<IService, Impl>` with an `internal` implementation works inside the same assembly.
- why: each cost a build or design iteration in B2b.

## 2026-10-30 · beth-online-shop F1 (frontend-react-dev)
- Applied to react-frontend-standards §2 (no case-only file name pairs), §5 (stretched real inputs, Modal onClose ref, tab bar hides only for text entry) and qa-automation E2E rules (centre-scroll under sticky bars, no force clicks).
### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md (§5 touch style)
- lesson: Hide the phone tab bar for text entry only (`:has(input:not([type=radio],[type=checkbox],[type=file]):focus, textarea:focus)`), never for any focused input, and never for selects, radios or checkboxes.
- why: with the rule on `input:focus`, tapping a variant chip hid the bottom bar and moved the sticky Add-to-cart bar; the next tap on Add landed on the moving layout and was lost (Playwright caught it as a first click that did nothing, only on phone sizes).

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md (§5 accessibility) and .claude/agents/qa-automation.md
- lesson: Custom radios, checkboxes and chips keep the real input but stretch it over the whole control (`position:absolute; inset:0; opacity:0`), not `sr-only` at 1px, so tap-size checks measure the real hit area; hidden file inputs use the `hidden` attribute.
- why: the F0 tap-target check flags every `input` under 48px, and 1px visually-hidden inputs would all have failed; the overlay input also makes the whole row the tap target.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md (§2 folder structure)
- lesson: Never name two files in one folder that differ only by letter case (`productForm.ts` and `ProductForm.tsx`); name the logic module `<thing>Model.ts` or `<thing>Schema.ts`.
- why: on Windows/macOS `tsc` failed with TS1149 (file name differs only in casing) and the import resolved to the wrong file; it would also break on case-sensitive CI.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/skills/react-frontend-standards/SKILL.md (§5 or §4)
- lesson: A shared Modal must keep the caller's latest `onClose` in a ref and run its focus/Escape/scroll-lock effect once per open, not on `[onClose]`, because callers pass inline arrows.
- why: the F0 Modal re-ran its effect on every parent render and moved focus back to the dialog frame each time a filter radio inside the sheet was chosen.

### 2026-10-30 · frontend-react-dev · beth-online-shop
- target: .claude/agents/qa-automation.md and .claude/agents/frontend-react-dev.md (screenshot checks)
- lesson: In Playwright specs with sticky bars, scroll the control to the centre (`el.scrollIntoView({block:'center'})`) and click it normally; avoid `check({force:true})`, which clicks whatever sits on top (the sticky bar) and reports "did not change its state" only on some sizes.
- why: the chip click passed at 375x667 and 1280x800 but failed at 390x844 because the sticky buy bar covered the chip at the default scroll position.

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
