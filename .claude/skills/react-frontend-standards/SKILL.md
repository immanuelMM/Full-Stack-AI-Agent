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
  via an npm script (e.g. `"api:types": "openapi-typescript http://localhost:5080/openapi/v1.json -o src/api/schema.d.ts"`).
  Use `openapi-fetch` (or a thin typed `fetch` wrapper) so request/response shapes are checked at compile time.
  Regenerate whenever the backend contract changes — a contract change should break the build, not production.
- API base URL from `import.meta.env.VITE_API_BASE_URL`.
- Every query/mutation UI handles loading, error and empty states.
- Auth (with the house JWT backend): access token kept in memory, refresh token in an HttpOnly cookie; on a 401,
  refresh once and retry, then redirect to login. Never store tokens in localStorage.

## 4. Routing, forms, state
- **React Router** (v7+) with lazy-loaded route modules for large pages.
- Forms: **React Hook Form + Zod** (`@hookform/resolvers/zod`). One Zod schema per form, shared with the
  TypeScript type via `z.infer`.
- Client-only state (cart, UI toggles): local state first, **Zustand** when it must be shared. Not for server data.

## 5. Styling, responsive, accessibility
- Mobile-first. Check ~360–430px, ~768px and ~1280px+.
- Use the project's existing approach (CSS modules / Tailwind); for new projects either is fine — pick one and stick to it.
- Semantic HTML, labelled inputs, visible focus, keyboard navigation, tap targets ≥ 44px, colour contrast WCAG AA.

## 6. Env and secrets
- `.env` is git-ignored; `.env.example` is committed with every variable and a safe placeholder.
- Everything prefixed `VITE_` is shipped to the browser — **never put secrets in the frontend**.

## 7. Testing
- **Vitest + React Testing Library** for components and hooks (query by role/label, not by class names).
- Mock the network with MSW rather than mocking fetch by hand.
- **Playwright** for end-to-end flows and mobile/desktop viewports.

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
- [ ] No secrets in `VITE_` vars or source; `.env.example` updated
- [ ] Tests added/updated for the changed behavior
