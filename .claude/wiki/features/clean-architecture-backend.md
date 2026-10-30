# Clean Architecture backend scaffold

Status: **implemented** — cafe-pos-system `d04812d` (reference), beth-online-shop `00a4328` (fresh scaffold from it).
IMMAN_HRIS is still a single project (split planned, M4-M8).

## What it does
`Domain → Application → Infrastructure → Api` solution (`.slnx`, CPM, `global.json`, `Directory.Build.props`) with
`Result`/`Error` + `ErrorKind`, repositories + `IUnitOfWork`, FluentValidation filter, ProblemDetails everywhere,
one `DependencyInjection.cs` per layer, health checks, dev seeder guarded by `IsDevelopment()`.

## When to reuse
Every new .NET backend. Start by copying beth's scaffold (newest, smallest) and keep cafe-pos as the fuller example.

## Reference implementation
- Solution/tooling: `beth-online-shop/backend/BethShop.slnx`, `beth-online-shop/backend/Directory.Build.props`,
  `beth-online-shop/backend/Directory.Packages.props`, `beth-online-shop/backend/global.json`, `beth-online-shop/backend/.editorconfig`.
- Result/Error: `cafe-pos-system/backend/src/CafePos.Application/Common/Result.cs`,
  `cafe-pos-system/backend/src/CafePos.Application/Common/ResultOfT.cs`, `cafe-pos-system/backend/src/CafePos.Application/Common/Error.cs`,
  `cafe-pos-system/backend/src/CafePos.Application/Common/ErrorKind.cs`, mapping `cafe-pos-system/backend/src/CafePos.Api/Http/ResultExtensions.cs`.
- Errors: `cafe-pos-system/backend/src/CafePos.Api/Http/GlobalExceptionHandler.cs`, `cafe-pos-system/backend/src/CafePos.Api/Http/ProblemResult.cs`;
  golden shape test `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/ProblemShapeTests.cs`.
- Validation: `cafe-pos-system/backend/src/CafePos.Api/Validation/FluentValidationFilter.cs`,
  `cafe-pos-system/backend/src/CafePos.Application/Common/Validation/` (shared rules, schema-required marker).
- Composition: `cafe-pos-system/backend/src/CafePos.Application/DependencyInjection.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/DependencyInjection.cs`, `cafe-pos-system/backend/src/CafePos.Api/DependencyInjection.cs`,
  `cafe-pos-system/backend/src/CafePos.Api/Program.cs`.
- Persistence: `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/CafeDbContext.cs` (also `IUnitOfWork`),
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/Repositories/`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/Configurations/`.
- Health: `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/DatabaseHealthCheck.cs` (`/health/live`, `/health/ready`).
- Dev seeder guard: `beth-online-shop/backend/src/BethShop.Infrastructure/Persistence/DevDataSeeder.cs`, test
  `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/DevSeedAndStorageTests.cs` (Production host + switch on → no rows).
- Test fixtures: `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/TestSupport.cs`,
  `cafe-pos-system/backend/tests/CafePos.Application.Tests/ResultAssertions.cs`.
- Docs: `cafe-pos-system/docs/architecture.md`, `cafe-pos-system/docs/adr/0001-repositories-and-unit-of-work.md`.

## Port to a new app
1. Copy beth's `backend/` minus `Features/*` (keep Auth, Shop settings if useful), rename `BethShop` → `<App>`.
2. Keep `ProblemShapeTests` + `ContractTests` + `SpaHostingTests`; delete feature tests you did not keep.
3. Add features under `Application/Features/<X>/` (DTOs, requests, validators, `I<X>Repository`, `<X>Service`).

## Gotchas
- EF: filter/order/page before the final `Select` into a record constructor.
- `dotnet-ef` must match the EF major (temp `--tool-path` if the global tool is older).
- Build-time OpenAPI runs `Program.cs` — see [OpenAPI contract](openapi-contract.md).
