# Lessons inbox

Agents append reusable lessons below (format in each agent's "Lessons" section). The `lessons-check.sh` Stop hook
blocks the lead from finishing while entries are here; the lead applies them to the target files, moves them to
`log.md`, clears this file back to this header, and commits. Entries start with `### `.

<!-- entries below this line -->

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/agents/qa-automation.md
- lesson: In a race test assert the loser's error code is the state machine's (`409 InvalidTransition`), not just "one request succeeded": the `xmin` backstop turns a missing lock into a different 409 (`Conflict`), so the code is what tells a lock from the backstop. Give each order its own interleaving (cancel/cancel/ship, confirm/cancel, ship x3, cash x2) so one run ends in different states, and put the outcome counts in `info.annotations`.
- why: with `LockOrderAsync` removed in a throwaway worktree (`E2E_BACKEND_PROJECT=<worktree csproj>`), all 4 race specs failed with "loser got 409 Conflict"; an "all but one fail" assertion would have stayed green.

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/agents/qa-automation.md
- lesson: Pin a known product bug with `test.fail(true, reason)` instead of a red test or a deleted assertion: it stays green while the bug exists and turns red when it is fixed. If the bug is a timing flash (a dialog that unmounts after a refetch), first wait for the refetch (e.g. the order header shows the new status), otherwise the test passes on a fast project and fails on a slow one.
- why: the "Cancel related COD orders" result dialog is unmounted by the order refetch; the pinned test passed ("expected to fail, but passed") on phone-small until it waited for the reload.

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/agents/frontend-react-dev.md
- lesson: A dialog that must stay open after its own mutation succeeds (to show the result) must not be gated on data that the mutation changes (`open && allowedActions.has(action)`): the refetch removes the action and unmounts the dialog before the result can be read. Keep the result in the page state, or key the dialog on "open" only.
- why: beth admin order detail: "Cancel related COD orders" cancels the viewed order too, so its "N orders cancelled" result never stays on screen (found by the full-stack E2E, invisible to the mocked unit tests).

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/wiki/features/e2e-playwright-harness.md
- lesson: Admin-flow recipe for the full-stack harness: set orders up through the API (`placePaid`, `placeCod`, `step`), do every staff step as a click, and after each step reload the customer's order page in a second EMPTY context (`freshContext`). To give orders different client IPs (cancel-related by IP) set `ForwardedHeaders__KnownProxies__0=127.0.0.1` in the stack env and send `X-Forwarded-For` from the API helper; browsers send none and stay 127.0.0.1. Reference: `beth-online-shop/e2e/support/stack/{adminUi,orderFlows,db}.ts`, `e2e/full/q3-*.spec.ts`.
- why: Q3 admin suite (fulfilment, roles, dashboard, inventory, races) built on it; 5 files, desktop + tablet-landscape + phone-small.

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/wiki/features/e2e-playwright-harness.md
- lesson: On a phone shell that hides its tab bar while a text field has focus (beth `.shell[data-typing]`, ~250 ms after blur), a nav helper that branches on `link.isVisible()` falls into the wrong branch (the More sheet) right after a form was typed into. Decide by section kind (primary tab vs manage page) and first wait for `expect(page.locator('.shell[data-typing]')).toHaveCount(0)`. Also: iterate with `E2E_KEEP_STACK=1 E2E_SKIP_BUILD=1` (DB and SPA build reused), and check ports with `netstat -ano | grep LISTENING` (TIME_WAIT rows from the last run look like a busy port).
- why: the Staff UI spec timed out for 60 s on phone-small only, after filling the COD block form, looking for "Orders" inside the More sheet.

### 2026-10-31 · qa-automation · beth-online-shop
- target: .claude/wiki/platforms/windows-dev-machine.md
- lesson: Git Bash paths such as `/c/Users/...` work for shell tools but not for `node -e "fs.readFileSync(...)"` (it resolves to `C:\c\Users\...`); pass `C:/Users/...` to node, or `cygpath -m`.
- why: reading a Playwright JSON report from the scratchpad with node failed with ENOENT until the path was written `C:/...`.
