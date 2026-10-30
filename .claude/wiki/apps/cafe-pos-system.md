# cafe-pos-system

Reflects app commit `d04812d` (2026-10-30). Paths are relative to `C:\Users\merin\AI\Agentic-fullstack-web-dev\`.

## Purpose
Multi-location cafe point of sale: menu catalog with variations/modifiers, POS + cash payment, receipts, orders,
recipe-based inventory with stock movements, staff time clock (4-digit PIN), branding + menu design studio.
**The reference layout for new full stack apps** (`cafe-pos-system/docs/architecture.md`, `cafe-pos-system/docs/adr/`).

## Stack
- .NET SDK 10.0.403 (`backend/global.json`), EF Core 10.0.14, Npgsql EF 10.0.3, FluentValidation 12, Scalar 2.18,
  JwtBearer 10.0.14, Testcontainers.PostgreSql 4.16, PostgreSQL 16.
- React 19.3, Vite 6.4, TypeScript 5.6, React Router 7.18, TanStack Query 5, RHF 7 + Zod 3, Zustand 5,
  openapi-typescript 7 + openapi-fetch 0.17, Vitest 4, Playwright 1.55 + @axe-core/playwright 4.10, Konva (design studio).

## Layout
```
backend/   CafePos.slnx, src/CafePos.{Domain,Application,Infrastructure,Api}, tests/CafePos.{Domain,Application}.Tests,
           tests/CafePos.Api.IntegrationTests, openapi/v1.json
frontend/  src/{app,api,components,features/<feature>,lib,styles,test}
e2e/       playwright.config.ts, global-setup.ts, support/{api,env,layout,ui,visual}.ts, tests/*.spec.ts, visual.mjs
deploy/    Dockerfile (single image), smoke-single-image.sh
docs/      architecture.md, deployment.md, adr/0001-0007, api/, plan/{cafe-pos-inventory,refactor,tablet-ui}-plan.md
render.yaml, docker-compose.yml, .github/workflows/ci.yml
```

## Status
- Inventory plan phases 1-2 (multi-location) done; refactor plan M1-M13 + D2 done (Clean Architecture, auth hardening,
  CI); tablet UI plan M1-M4 done (tokens/layers, shell, POS, payment keypad + auto-print), M5-M10 not started.
- Deployed on Render free (one service + free Postgres, created 2026-10-29). See [Render](../platforms/render.md).

## Key decisions (ADRs)
- 0001 repositories + unit of work · 0002 built-in OpenAPI + Scalar · 0003 committed contract snapshot with drift tests ·
  0004 generated frontend types with openapi-fetch · 0005 atomic refresh-token claim + cross-tab Web Locks ·
  0006 rate-limit partitions + forwarded-headers trust · 0007 keep 4-digit time-clock PINs.
- One Render service serving API + SPA (same origin); migrate on startup while on the free plan.

## Run and test
- Dev stack: `docker compose up -d` (db, api :5080, web :5173). Dev seed in Development only.
- Backend: `cd backend && dotnet build && dotnet test` (Testcontainers; Docker must be running).
- Frontend: `cd frontend && npm run lint && npm run build && npm test && npm run format:check`.
- E2E isolated: `cafe-pos-system/e2e/docker-compose.e2e-iso.yml` with `-p cafepos-e2e`, ports 15173/15080/15433, then
  `E2E_BASE_URL=http://localhost:15173 E2E_API_URL=http://localhost:15080 npx playwright test --project=<one>`.

## Features implemented here
- [JWT + refresh auth](../features/jwt-refresh-auth.md) · [Clean Architecture backend](../features/clean-architecture-backend.md) ·
  [OpenAPI contract](../features/openapi-contract.md) · [Rate limiting + forwarded headers](../features/rate-limiting-forwarded-headers.md)
- [Touch UI shell](../features/touch-ui-shell.md) · [On-screen keypad](../features/onscreen-keypad.md) · [Printing](../features/printing.md)
- [E2E harness](../features/e2e-playwright-harness.md) · [GitHub Actions CI](../features/github-actions-ci.md) ·
  [Same-origin single-image deploy](../features/same-origin-single-image-deploy.md)
- [Idempotent checkout](../features/idempotent-checkout-reservations.md) (order completion with `Idempotency-Key`) ·
  [Multi-location isolation](../features/multi-location-isolation.md)
