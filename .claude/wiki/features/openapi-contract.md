# OpenAPI snapshot + contract test + generated TS types

Status: **implemented** — cafe-pos-system `d04812d`, beth-online-shop `00a4328`. IMMAN_HRIS: planned (M3 / F1).

## What it does
Backend generates `backend/openapi/v1.json` at build time and commits it; a test fails when the live document differs;
the frontend runs `openapi-typescript` on the committed file into `src/api/schema.d.ts` and calls the API with
`openapi-fetch`; CI regenerates both and fails on any diff.

## Reference implementation
- `cafe-pos-system/backend/src/CafePos.Api/OpenApi/OpenApiDocumentSetup.cs` (Bearer scheme, transformers),
  `cafe-pos-system/backend/src/CafePos.Api/OpenApi/ValidatorRulesSchemaTransformer.cs` (FluentValidation rules into the schema),
  `cafe-pos-system/backend/src/CafePos.Api/OpenApi/ContractOrderDocumentTransformer.cs` (stable ordering).
- Build-time skip: `cafe-pos-system/backend/src/CafePos.Infrastructure/BuildEnvironment.cs` (entry assembly `GetDocument.Insider`).
- Snapshot + test: `cafe-pos-system/backend/openapi/v1.json`,
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/ContractTests.cs`; beth: `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/ContractTests.cs`.
- Frontend: `gen:api` script in `cafe-pos-system/frontend/package.json`, aliases `cafe-pos-system/frontend/src/api/types.ts`,
  client `cafe-pos-system/frontend/src/lib/apiClient.ts`, `cafe-pos-system/frontend/.prettierignore` (generated file excluded).
- ADRs: `cafe-pos-system/docs/adr/0002-builtin-openapi.md`, `cafe-pos-system/docs/adr/0003-committed-contract-snapshot.md`,
  `cafe-pos-system/docs/adr/0004-generated-frontend-types.md`. CI job `contract` in `cafe-pos-system/.github/workflows/ci.yml`.

## Commands
```
cd backend && dotnet build src/<App>.Api -p:OpenApiGenerateDocuments=true
cd frontend && npm run gen:api     # openapi-typescript ../backend/openapi/v1.json -o src/api/schema.d.ts
```
Commit code + `v1.json` + `schema.d.ts` together.

## Port
Copy the `OpenApi/` folder, `BuildEnvironment.cs`, the `Microsoft.Extensions.ApiDescription.Server` package reference,
`ContractTests.cs`, the `gen:api` script and the CI `contract` job.

## Gotchas
- Shared working copy with an uncommitted snapshot from another agent: `git show HEAD:backend/openapi/v1.json > $TEMP/v1.json`
  and generate from that.
- Register `JsonStringEnumConverter` in `ConfigureHttpJsonOptions` (the generator reads it), then check enum schemas
  in the snapshot are strings.
- .NET 10 emits `["number","string"]` for numbers: strip the union with a schema transformer.
- Never run Prettier on `schema.d.ts`; keep it in `.prettierignore`.
- Keep `[ProducesResponseType]` accurate; add `[Consumes]`/`[Produces]` on multipart and file endpoints.
