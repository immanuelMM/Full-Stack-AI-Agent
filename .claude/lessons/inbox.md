# Lessons inbox

Agents append reusable lessons below (format in each agent's "Lessons" section). The `lessons-check.sh` Stop hook
blocks the lead from finishing while entries are here; the lead applies them to the target files, moves them to
`log.md`, clears this file back to this header, and commits. Entries start with `### `.

<!-- entries below this line -->

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
