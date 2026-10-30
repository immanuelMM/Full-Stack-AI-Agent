---
name: react-frontend-standards
description: House standards for React + TypeScript frontends and static websites in this workspace — tooling, folder structure, data fetching, typed API client generated from OpenAPI, forms/validation, state, styling, accessibility, env/secrets, testing, and Astro for static sites. Load before creating, scaffolding, restructuring, or reviewing a frontend.
---

# Frontend Standards

Default rules for every frontend. A project's existing, deliberate conventions win over this file — when
they conflict, follow the project and say so.

## 1. Tooling
- **TypeScript everywhere**, `strict: true`. No `any` without a comment explaining why.
- **Vite** + `@vitejs/plugin-react` for SPAs. Latest React (19+).
- ESLint (flat config, `typescript-eslint`, `eslint-plugin-react-hooks`) + Prettier. `npm run lint` and
  `npm run build` (which runs `tsc --noEmit`) must pass before a task is done.
- Commit `package-lock.json`. Use `npm ci` in CI. Check the latest stable version before adding a package.

## 2. Folder structure (organise by feature)
```
frontend/
├─ src/
│  ├─ app/          # App root, router, providers (QueryClient, theme), layout
│  ├─ features/     # One folder per feature: components, hooks, api calls, schemas, tests
│  │  └─ orders/    # OrdersPage.tsx, useOrders.ts, orderSchema.ts, OrdersPage.test.tsx
│  ├─ components/   # Shared, presentational UI (Button, Dialog, …)
│  ├─ lib/          # api client, utilities, formatting
│  └─ api/          # generated OpenAPI types (do not hand-edit)
├─ .env.example
└─ vite.config.ts
```

## 3. Data fetching and the API contract
- **TanStack Query** for all server state (queries, mutations, cache invalidation). Don't copy server data into
  global state.
- **Types come from the backend's OpenAPI spec**, generated with `openapi-typescript` into `src/api/schema.d.ts`
  via an npm script that reads the backend's **committed** snapshot, not a running server
  (`"gen:api": "openapi-typescript ../backend/openapi/v1.json -o src/api/schema.d.ts"`); commit the generated file
  and let CI fail when regenerating it produces a diff.
  Use `openapi-fetch` (or a thin typed `fetch` wrapper) so request/response shapes are checked at compile time.
  Regenerate whenever the backend contract changes — a contract change should break the build, not production.
- API base URL from `import.meta.env.VITE_API_BASE_URL`.
- Every query/mutation UI handles loading, error and empty states.
- Auth (with the house JWT backend): access token kept in memory, refresh token in an HttpOnly cookie; on a 401,
  refresh once and retry, then redirect to login. Never store tokens in localStorage.
  - **Clear the session only when the refresh returns 401/403.** A 429, 5xx or network error keeps the session and
    fails only the current request — otherwise a throttled refresh logs everyone out.
  - **Single-flight refresh across tabs** with the Web Locks API (`navigator.locks.request('<app>-refresh', …)`),
    falling back to per-tab single-flight. Two tabs refreshing with the same rotated cookie trip the backend's
    token-theft detection and log the user out everywhere.
  - Rebuild a retried request lazily (only after a 401) — don't clone every request body up front (large uploads).
- **Query keys are derived from the params actually sent** (`queryKey: ['orders', query]`), never maintained
  separately from them.
- Validate `VITE_API_BASE_URL` format at startup with a clear error rather than string-replacing path suffixes.

## 4. Routing, forms, state
- **React Router** (v7+) with lazy-loaded route modules for large pages.
- Forms: **React Hook Form + Zod** (`@hookform/resolvers/zod`). One Zod schema per form, shared with the
  TypeScript type via `z.infer`.
- Client-only state (cart, UI toggles): local state first, **Zustand** when it must be shared. Not for server data.

## 5. Styling, responsive, accessibility
- **Three versions, always:** every screen is designed, built and screenshot-checked for **web** (desktop ≥ 1024px,
  mouse; denser layout is fine), **tablet** (768–1180px, portrait and landscape) and **phone** (360–430px, down to
  375×667). Mobile-first CSS. Tablet and phone always get the touch style below, styled like
  `../cafe-pos-system/frontend` (the reference: read its tokens, shell, nav and buttons before designing): big
  buttons, large type, generous spacing, one obvious primary action per screen.
- Use the project's existing approach (CSS modules / Tailwind); for new projects either is fine — pick one and stick to it.
- Semantic HTML, labelled inputs, visible focus, keyboard navigation, tap targets ≥ 44px, colour contrast WCAG AA.
- **CSS structure:** tokens (custom properties) plus `@layer` files (reset, tokens, base, layout, components, features,
  utilities); the layer-order statement must be the first CSS the bundle emits (import it first in `main.tsx`). Print CSS
  that needs `!important` stays unlayered. Brand colours set at runtime stay as inline vars that tokens reference.
- **Scope every size-specific rule inside its media/container query.** Unit tests run without CSS (jsdom), so a phone rule
  that leaks onto tablets passes every Vitest test — only a real browser at each size catches it.
- **Touch style (tablet + phone, every app):** one DOM for every size (CSS changes the layout, never a second copy of the nav, or
  `getByRole` queries break); the shell fills `100dvh` with `env(safe-area-*)` and `viewport-fit=cover`, and only the
  content area scrolls; default controls 56px, primary 64px, never under 48px; money/PIN entry uses an on-screen keypad
  with the real `<input>` kept (`inputMode="none"` on `(pointer: coarse)`, no autofocus) so the OS keyboard never covers
  the screen; check the smallest phone too (375×667), not just 390×844.
- Browsers cannot print silently: "auto-print" means calling `window.print()` once per document (guard against StrictMode
  double effects) and keeping a "Print again" button. Silent printing needs a kiosk flag or a local print agent.
- For same-origin hosting (API serves the SPA), allow a root-relative API base (`/api/v1`) so no hostname is baked in.

## 6. Env and secrets
- `.env` is git-ignored; `.env.example` is committed with every variable and a safe placeholder.
- Everything prefixed `VITE_` is shipped to the browser — **never put secrets in the frontend**.

## 7. Testing
- **Vitest + React Testing Library** for components and hooks (query by role/label, not by class names).
- Mock the network with MSW rather than mocking fetch by hand.
- **Playwright** for end-to-end flows and mobile/desktop viewports.
- Set `configure({ asyncUtilTimeout: 5000 })` in the test setup — the 1 s default flakes on loaded machines and CI.
- `npm run format:check` covers Markdown too (README tables fail CI). Never run `prettier --write` on generated files
  (`src/api/schema.d.ts`); keep them in `.prettierignore`.

## 8. Static websites
- **Astro + TypeScript** by default (content collections for blog/docs-style content, zero JS unless an
  island needs it). Plain HTML/CSS/JS is fine for a single page.
- Lives in `<app-folder>/site/`. SEO basics: unique `<title>`/description per page, Open Graph tags,
  `sitemap.xml`, `robots.txt`, optimised images (`astro:assets`).
- Targets: Lighthouse ≥ 90 for performance, accessibility, best practices and SEO.
- Deploys as static files (Cloudflare Pages, Netlify or GitHub Pages).

## 9. Checklist before finishing a frontend task
- [ ] `npm run lint` and `npm run build` pass
- [ ] API types regenerated if the backend contract changed; no hand-written duplicates of API shapes
- [ ] Loading / error / empty states handled
- [ ] Works at mobile, tablet and desktop widths; keyboard accessible
- [ ] For UI changes: screenshots taken at each target size **and looked at** (key buttons fully on screen, nothing
      clipped) — passing tests alone missed a hidden keypad row
- [ ] `npm run format:check` passes
- [ ] No secrets in `VITE_` vars or source; `.env.example` updated
- [ ] Tests added/updated for the changed behavior
