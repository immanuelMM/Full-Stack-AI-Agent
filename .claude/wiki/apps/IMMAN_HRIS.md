# IMMAN_HRIS

Reflects app commit `d4c2e28` on `main` (2026-10-30; `refactor/clean-arch` merged as PR #3). Paths are relative to
`C:\Users\merin\AI\Agentic-fullstack-web-dev\`. Remote: `git@github.com:immanuelMM/IMMAN_HRIS.git`.

## Purpose
Live HR information system with real data (PII): employees, departments/positions, QR ID cards (designer, templates,
printing), QR scan attendance with a kiosk, employee portal (profile, time in/out), exports (PDF/Word/Excel),
notification settings (SMTP/SMS secrets via Data Protection), JSON backup/restore. Philippine wall-clock timestamps.

## Stack
- .NET SDK 10.0.100 (`global.json`), EF Core/JwtBearer 10.0.14, Npgsql EF 10.0.3, QuestPDF, ClosedXML, OpenXml,
  PostgreSQL 16. Backend is still **one project** (`backend/HRIS.Api`); the Clean Architecture split (M4-M8) is planned.
- React 19.2, Vite 8.3, TypeScript 6, React Router 7 (`react-router-dom`), TanStack Query 5 (provider only so far),
  axios (to be replaced by openapi-fetch in F1), html5-qrcode 2.3.8, oxlint, Vitest 4, Playwright + axe.

## Layout
```
backend/   HRIS.Api/{Controllers,DTOs,Data,Models,Services,Migrations}, tests/Hris.Api.IntegrationTests (golden files)
frontend/  src/{api,app,components,context,lib,pages/{admin,portal},styles,test,utils}
e2e/       docker-compose.e2e.yml, playwright.config.ts, playwright.screenshots.config.ts, scripts/, support/, tests/, shots/
docs/      plan/{refactor,ui-responsive}-plan.md, plan/baseline/, deploy/r1-signing-keys.md
Dockerfile (single image), docker-compose.yml, run.md, .github/workflows/ci.yml
```

## Status
- Done: M0 baseline, M1 characterization tests (209 integration + frontend unit + Playwright smoke), M2 .NET 10 (R1),
  F3 signing-key split (QR v2), D1 CI, F0 frontend structure, U1 layers/tokens, U2 shell, U5 portal + scan kiosk +
  PIN login, U3 admin core.
- Planned: M3 built-in OpenAPI + snapshot (G1), M4-M8 Clean Architecture, F1-F4 typed client/TanStack/RHF/session,
  U4, U6, QA-T2, R2. Fixes F1-F7 approved; F8/F9 after R2.
- Hosted on Render free (Postgres free: 30-day expiry, no backups) — the user takes a `pg_dump` before every deploy.

## Key decisions (refactor + UI plans)
- Real data must survive: characterization + golden tests before any restructure; rehearse each model-touching
  milestone on a restored production dump in a throwaway container.
- QR cards: new `HRISID2:` codes signed with `QrSigning:Key`; old `HRISID:` cards verify only via `QrSigning:LegacyKey`;
  QR keys never derive from `Jwt:Key` (runbook `IMMAN_HRIS/docs/deploy/r1-signing-keys.md`).
- UI: pointer-based tablet layout at ≥ 1024px; kiosk mode with admin-password exit; rear camera default + remembered
  Front/Back switch; primary fill `#0f766e`; dark mode follows the OS; UI work started before F1-F4.
- Keep unversioned `/api` routes; keep `MigrateOnStartup` on while on Render free.

## Run and test
- Whole app: `docker compose up -d --build` → http://localhost:8080 (see `IMMAN_HRIS/run.md`).
- Backend: `cd backend && dotnet test tests/Hris.Api.IntegrationTests` (Testcontainers `postgres:16-alpine`).
- Frontend: `cd frontend && npm run lint && npm run build && npm test`.
- E2E: own project `hris-e2e` (`IMMAN_HRIS/e2e/docker-compose.e2e.yml`, db :15432 on tmpfs, API :15080); projects
  `phone-small`, `phone`, `tablet`, `tablet-landscape`, `desktop`, run one at a time.

## Features implemented here
- [Signed QR codes + key rotation](../features/signed-qr-codes.md) · [QR attendance + kiosk](../features/qr-attendance-kiosk.md)
- [Touch UI shell](../features/touch-ui-shell.md) · [On-screen keypad](../features/onscreen-keypad.md) (PIN) ·
  [Printing](../features/printing.md) (ID cards)
- [E2E harness](../features/e2e-playwright-harness.md) (fake camera, 5 projects, screenshot compare) ·
  [GitHub Actions CI](../features/github-actions-ci.md) · [Characterization-first refactor](../features/characterization-refactor.md)
