# Same-origin single-image deploy (API serves the SPA) + production startup helpers

Status: **implemented** — cafe-pos-system `d04812d` (live on Render), backend parts copied into beth-online-shop
`00a4328` (its `deploy/` is planned for D1). IMMAN_HRIS has its own single image (`IMMAN_HRIS/Dockerfile`).

## What it does
- One multi-stage image: Node builds the SPA with `VITE_API_BASE_URL=/api/v1` (root-relative), .NET publishes the API,
  runtime `aspnet` image (non-root, port 8080) serves both; `Spa__RootPath` turns on static files + `index.html` fallback.
- Fallback never answers `/api`, `/health`, `/openapi` (unknown API routes stay problem+json 404) and is not in OpenAPI.
- `DATABASE_URL` (`postgres://…`) parsed in C# via `NpgsqlConnectionStringBuilder` (SSL required, GSS disabled);
  an explicit `ConnectionStrings__Default` wins.
- Startup migrate retries transient errors (bounded backoff); optional startup work logs and continues.
- First-owner bootstrap from `Bootstrap__*` for shell-less hosts + one-time owner password reset (also clears lockout).
- CI builds the production image and runs a smoke check.

## Reference implementation
- Image + smoke: `cafe-pos-system/deploy/Dockerfile`, `cafe-pos-system/deploy/smoke-single-image.sh`, `cafe-pos-system/.dockerignore`.
- Blueprint: `cafe-pos-system/render.yaml`; guide `cafe-pos-system/docs/deployment.md` ("Render").
- SPA hosting: `cafe-pos-system/backend/src/CafePos.Api/Http/SpaHosting.cs`; test `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/SpaHostingTests.cs`.
- DB URL: `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/ConnectionStringResolver.cs`; test
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/DatabaseUrlTests.cs`.
- Startup: `cafe-pos-system/backend/src/CafePos.Api/DatabaseStartup.cs`.
- Bootstrap: `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/OwnerBootstrapper.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/OwnerPasswordReset.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/BootstrapOptions.cs`; tests
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/OwnerBootstrapTests.cs`,
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/OwnerPasswordResetTests.cs`.
- Frontend relative base: `resolveApiBase` in `cafe-pos-system/frontend/src/lib/apiClient.ts`.

## Config (production)
`ASPNETCORE_ENVIRONMENT=Production`, `DATABASE_URL` or `ConnectionStrings__Default` (with `GSS Encryption Mode=Disable`),
`Jwt__Key`, `Spa__RootPath` (set in the image), `Database__MigrateOnStartup` (true only for a single instance without
pre-deploy), `Database__SeedDevData=false`, `ForwardedHeaders__*`, `Bootstrap__OwnerEmail/OwnerPassword/OwnerName/
LocationName/LocationTimeZone/LocationVatRatePercent` (cafe), `Bootstrap__ResetOwnerEmail/ResetOwnerPassword`.
Give the user example values: IANA zone `Asia/Manila` (not `GMT+8`), VAT `12`.

## Port
1. Copy `deploy/Dockerfile` + smoke script, adjust project names and the SPA build; copy `SpaHosting`, `ConnectionStringResolver`,
   `DatabaseStartup`, the bootstrap pair and their tests.
2. Add the CI `docker` job (build + smoke) and, for Render, a `render.yaml` ([Render](../platforms/render.md)).

## Gotchas
- Security headers on the SPA fallback and static files from config (beth `SpaSecurityHeaders.cs`): no-referrer,
  DENY, nosniff, CSP with img-src + R2 origin. Vite output needs no `'unsafe-inline'` (React `style` props are CSSOM).
- Bootstrap acts only when the users table is empty, inside a transaction with an advisory lock; validates every value
  up front and logs why it skipped; warns on every start while the password var is set. It runs independently of
  `MigrateOnStartup`.
- Confirm the user actually logged in before telling them to delete the bootstrap vars.
- Never log secrets or full emails (mask them).
- Keep the single-image Dockerfile in sync with the per-project Dockerfiles used for local compose.
