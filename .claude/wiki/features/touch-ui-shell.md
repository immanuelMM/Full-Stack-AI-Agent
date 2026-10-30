# Touch UI shell (sidebar / rail / bottom tabs + More sheet), tokens and CSS layers

Status: **implemented** — cafe-pos-system `d04812d` (the named touch-style reference), ported to IMMAN_HRIS `d4c2e28`
(U1/U2) and beth-online-shop `00a4328` (StoreShell + AdminShell).

## What it does
- One DOM for every size; CSS re-lays it out: left rail (88px expanded, 80px medium) on tablets/desktop, top app bar +
  64px bottom tabs (+ "More" sheet holding the manage links, rendered only while open) on phones. "Log out" is always a
  directly visible button.
- Shell is a flex column filling `100dvh` with `env(safe-area-*)`; only `main` scrolls; bottom bar hides while a text
  input is focused.
- Design tokens (custom properties) and cascade layers `reset, tokens, base, layout, components, features, utilities`;
  print CSS unlayered.
- Touch sizes: controls 56px, primary 64px, never < 48px; inputs ≥ 16px font (no iOS zoom); hover only under
  `(hover: hover) and (pointer: fine)`; `touch-action: manipulation`; pressed feedback on `:active`.

## Size classes (cafe-pos; HRIS splits web vs tablet by pointer type at ≥ 1024px)
| Class | Query | Shell |
|---|---|---|
| compact | `(max-width: 599px), (max-height: 499px)` | app bar + bottom tabs + More sheet |
| medium | `600–959px wide, ≥ 500px tall` | 80px rail |
| expanded | `≥ 960px wide, ≥ 500px tall` | 88px rail |
| large | `≥ 1300px wide` | 88px rail, roomier panes |
Container queries (`container-type: inline-size`) inside components whose layout depends on their own width.

## Reference implementation
- cafe-pos: `cafe-pos-system/frontend/src/app/AppShell.tsx`, `cafe-pos-system/frontend/src/styles/index.css` (layer order, imported
  first in `cafe-pos-system/frontend/src/main.tsx`), `cafe-pos-system/frontend/src/styles/tokens.css`,
  `cafe-pos-system/frontend/src/styles/layout.css`, `cafe-pos-system/frontend/src/styles/base.css`,
  `cafe-pos-system/frontend/src/styles/components.css`, `cafe-pos-system/frontend/src/components/ui.tsx`,
  `cafe-pos-system/frontend/src/components/Modal.tsx` (dialog / side / full sheets), `cafe-pos-system/frontend/src/lib/useMediaQuery.ts`,
  `cafe-pos-system/frontend/src/app/useFullscreen.ts`, `cafe-pos-system/frontend/public/manifest.webmanifest`, `cafe-pos-system/frontend/index.html` (viewport meta).
- Design rationale: `cafe-pos-system/docs/plan/tablet-ui-plan.md` §1-2 (touch sizes, type scale, nav by size, dvh/safe areas, iOS keyboard).
- IMMAN_HRIS port: `IMMAN_HRIS/frontend/src/app/AppShell.tsx`, `IMMAN_HRIS/frontend/src/app/layouts/adminNav.ts`,
  `IMMAN_HRIS/frontend/src/lib/breakpoints.ts`, `IMMAN_HRIS/frontend/src/styles/tokens.css`; plan `IMMAN_HRIS/docs/plan/ui-responsive-plan.md` §3.
- beth: `beth-online-shop/frontend/src/app/StoreShell.tsx`, `beth-online-shop/frontend/src/app/AdminShell.tsx`, `beth-online-shop/frontend/src/styles/`.
- Tests: `cafe-pos-system/frontend/src/app/AppShell.test.tsx`, `IMMAN_HRIS/frontend/src/app/AppShell.test.tsx`,
  `cafe-pos-system/e2e/tests/layout.spec.ts`, `IMMAN_HRIS/e2e/tests/shell-nav.spec.ts`, layout helpers in
  [E2E harness](e2e-playwright-harness.md).

## Port to a new app
1. Copy `styles/` (index, reset, tokens, base, layout, components, utilities, print) and import `index.css` first in `main.tsx`.
2. Copy `AppShell`, `Modal`, `ui.tsx`, `useMediaQuery`; replace nav items and brand tokens (keep the size tokens).
3. Copy the layout helpers + Playwright projects and screenshot every screen at each size before calling it done.

## Gotchas
- Admin and storefront CSS share layers: grep both bundles before naming a class (beth's admin `.chips`/`.link-btn`
  collided with `catalog.css` and wrapped the order tabs — renamed `.view-tab(s)`).
- Tab bar hidden while typing: restore it ~250 ms after blur via a data attribute set by focus/blur handlers on the
  shell (beth `beth-online-shop/frontend/src/app/StoreShell.tsx`, `store.css`). Instant `:has(:focus)` loses the first
  tap on sticky buttons. beth's AdminShell does the same since F3 (`b2bc927`).
- Full-card radios: the real input covers the label; draw the dot on the wrapper's `::before` with `pointer-events: none`
  and leave the face unpositioned, or Playwright reports "intercepts pointer events".
- Splitting a flat stylesheet into layers can silently flip which rule wins; Vite/lightningcss may drop the leading
  `@layer` statement — check `--minify false` output and give every layer a non-empty block in eager CSS.
- A fixed-row grid shell leaves a gap when an optional banner is absent; use the flex column.
- Duplicate nav trees break `getByRole` in jsdom (CSS is off in Vitest).
- Runtime brand colours stay inline vars that tokens reference.
