---
name: dotnet-backend-standards
description: House standards for any C# / ASP.NET Core Web API backend — solution structure (Clean Architecture), repository + unit-of-work pattern, JWT access/refresh-token auth, validation, error handling, OpenAPI, testing. Load before creating, scaffolding, restructuring, or reviewing a .NET backend in any project.
---

# .NET Backend Standards

These are the default rules for every .NET backend. A project's own CLAUDE.md or existing,
deliberate conventions win over this file — when they conflict, follow the project and say so.
Working code for these rules lives in the knowledge base: check
`C:\Users\merin\AI\Agentic-fullstack-web-dev\full-stack-agent\.claude\wiki\index.md` and copy the reference
implementation (scaffold, auth, OpenAPI, rate limiting, deploy helpers) before writing it yourself.

## 1. Target framework & tooling
- **New projects:** latest .NET **LTS** (currently **.NET 10**, C# 14). Run `dotnet --list-sdks`
  first; if the LTS SDK is missing, tell the user and use the newest installed LTS rather than silently downgrading.
- **Existing projects:** keep their target framework. Upgrade only when asked.
- Pin the SDK with `global.json` (`rollForward: latestFeature`).
- `Directory.Build.props` at the root: `Nullable=enable`, `ImplicitUsings=enable`,
  `TreatWarningsAsErrors=true` (at least in CI), `AnalysisLevel=latest-recommended`.
- **Central Package Management:** `Directory.Packages.props` with `ManagePackageVersionsCentrally=true`;
  csproj files reference packages without versions.
- Use the `.slnx` solution format on .NET 10 SDK (`.sln` on older SDKs).
- `.editorconfig` committed; file-scoped namespaces; one public type per file.

## 2. Solution structure (Clean Architecture)

```
<App>/
├─ global.json  Directory.Build.props  Directory.Packages.props  .editorconfig  <App>.slnx
├─ src/
│  ├─ <App>.Domain/          # Entities, value objects, enums, domain errors/events. NO dependencies.
│  ├─ <App>.Application/     # Use cases: services, DTOs, validators, repository & service INTERFACES,
│  │                         # Result types, mapping. Depends on Domain only.
│  ├─ <App>.Infrastructure/  # EF Core DbContext, configurations, migrations, repository implementations,
│  │                         # UnitOfWork, JWT token service, password hashing, external APIs, email, clock.
│  │                         # Depends on Application (+ Domain).
│  └─ <App>.Api/             # Controllers or minimal-API endpoint groups, middleware, auth setup,
│                            # OpenAPI, Program.cs composition root. Depends on Application + Infrastructure.
└─ tests/
   ├─ <App>.Domain.Tests/ & <App>.Application.Tests/   # unit tests (xUnit)
   └─ <App>.Api.IntegrationTests/                       # WebApplicationFactory + Testcontainers
```

Dependency rule: `Api → Infrastructure → Application → Domain`. Inner layers never reference outer ones.
Each layer exposes one `DependencyInjection.cs` with `AddApplication()` / `AddInfrastructure(config)` /
`AddApi()` extension methods so `Program.cs` stays short.

Inside Application, organise **by feature**, not by technical type:
```
Application/
├─ Common/            # Result<T>, Error, paging, interfaces (IUnitOfWork, ICurrentUser, ITokenService…)
└─ Features/
   ├─ Auth/           # LoginRequest, AuthResponse, AuthService, validators
   └─ Products/       # ProductDto, CreateProductRequest, IProductRepository, ProductService, validators
```

Small apps / prototypes may collapse to a single Api project, but keep the same folders
(Domain/, Application/, Infrastructure/) so it can be split later without rewrites.

## 3. Domain layer
- Entities own their invariants: private setters, constructors/factory methods, behaviour methods
  (`order.AddItem(...)`) instead of anaemic property bags.
- Common base: `Entity` (Id), optional `AuditableEntity` (CreatedAt/By, UpdatedAt/By) filled by an EF interceptor.
- Money as `decimal`; times as `DateTimeOffset` in UTC; inject `TimeProvider` — never `DateTime.Now`.
- No EF attributes in Domain — mapping lives in `IEntityTypeConfiguration<T>` classes in Infrastructure.

## 4. Repository + Unit of Work pattern
- **Interfaces in Application, implementations in Infrastructure.**
- **One repository per aggregate root** (`IOrderRepository`, `IProductRepository`) with intention-revealing
  methods. A thin generic base is allowed for shared plumbing, but don't expose a bare `IRepository<T>` to services.
- Repositories return **domain entities or DTO projections — never `IQueryable`**. Filtering/paging
  happens inside the repository.
- Repositories **do not call `SaveChanges`**. `IUnitOfWork.SaveChangesAsync(ct)` commits — implemented by the DbContext
  (or a wrapper). Use an explicit transaction only when a use case spans multiple `SaveChanges`.
- All methods `async`, take a `CancellationToken`, and use `AsNoTracking()` for read-only queries.
- Read-heavy list/report queries may project straight to DTOs with `.Select(...)` inside the repository.

```csharp
// Application/Features/Products/IProductRepository.cs
public interface IProductRepository
{
    Task<Product?> GetByIdAsync(Guid id, CancellationToken ct);
    Task<PagedResult<ProductDto>> ListAsync(ProductQuery query, CancellationToken ct);
    Task<bool> SkuExistsAsync(string sku, CancellationToken ct);
    void Add(Product product);
    void Remove(Product product);
}

// Application/Common/IUnitOfWork.cs
public interface IUnitOfWork { Task<int> SaveChangesAsync(CancellationToken ct = default); }

// Infrastructure/Persistence/Repositories/ProductRepository.cs
internal sealed class ProductRepository(AppDbContext db) : IProductRepository
{
    public Task<Product?> GetByIdAsync(Guid id, CancellationToken ct) =>
        db.Products.FirstOrDefaultAsync(p => p.Id == id, ct);

    public Task<bool> SkuExistsAsync(string sku, CancellationToken ct) =>
        db.Products.AsNoTracking().AnyAsync(p => p.Sku == sku, ct);

    public void Add(Product product) => db.Products.Add(product);
    public void Remove(Product product) => db.Products.Remove(product);
    // ListAsync: AsNoTracking + filter + order + Skip/Take + Select to ProductDto
}

// Application/Features/Products/ProductService.cs
public sealed class ProductService(IProductRepository products, IUnitOfWork uow)
{
    public async Task<Result<ProductDto>> CreateAsync(CreateProductRequest req, CancellationToken ct)
    {
        if (await products.SkuExistsAsync(req.Sku, ct)) return ProductErrors.DuplicateSku;
        var product = Product.Create(req.Name, req.Sku, req.Price);
        products.Add(product);
        await uow.SaveChangesAsync(ct);
        return product.ToDto();
    }
}
```

Register repositories as **Scoped** (same lifetime as the DbContext).

## 5. Application layer
- Services (or handlers) return `Result` / `Result<T>` with typed `Error`s (NotFound, Validation, Conflict,
  Unauthorized, Forbidden) for expected failures. **Exceptions are for unexpected failures only.**
- DTOs are `record`s. **Never return EF entities from the API.** Map with hand-written extension
  methods (`ToDto()`) or Mapperly (source-generated) — avoid reflection mappers.
- Validation with **FluentValidation** validators per request (or built-in minimal-API validation on .NET 10
  when the project uses minimal APIs). Validate at the boundary, before the service runs.
- No MediatR by default — plain services are enough. Add CQRS/mediator only if the user asks.

## 6. Infrastructure layer
- EF Core with the project's provider (PostgreSQL/Npgsql or SQL Server); configurations via `ApplyConfigurationsFromAssembly`.
- **Migrations are committed** and generated via `dotnet ef migrations add` — never hand-edit the DB schema.
  Apply with a migration bundle or explicit step in deployment, not automatically at startup in production.
  Use a `dotnet-ef` matching the EF major (a temp `--tool-path` if the global one is older). Rebuild before running
  tests after adding a migration (`--no-build` on a stale build fails every test with PendingModelChangesWarning).
- **Major upgrades:** run the full suites unchanged on the new framework; check raw ADO reads for changed CLR types,
  drop references the framework now ships (NU1510) and align EF package versions (MSB3277). Known .NET 8 → 10
  breaks: `.claude/wiki/features/characterization-refactor.md`.
- Check a library's licence before recommending it. Re-encode uploads with SkiaSharp (MIT) by default; refuse
  oversized images from header dimensions (`SKCodec.Info`) before decoding; apply the EXIF orientation to the pixels
  before re-encoding (Skia's decode ignores it); test with a JPEG carrying an injected Orientation tag.
  Pipeline + licence notes: `.claude/wiki/features/image-upload-pipeline.md`.
- EF queries: filter/order/page before the final `Select` into a record constructor (`new Dto(...)`); filtering or
  ordering on such a projection fails at runtime ("could not be translated").
- Interceptors for audit fields / soft delete. Optimistic concurrency (`RowVersion` / `xmin`) on entities edited concurrently.
- Strongly-typed options (`JwtOptions`, …) via `AddOptions<T>().BindConfiguration(...).ValidateDataAnnotations().ValidateOnStart()`.

## 7. Authentication — JWT access + refresh tokens
- Package: `Microsoft.AspNetCore.Authentication.JwtBearer`. Passwords via ASP.NET Core Identity
  (`UserManager` / `PasswordHasher<T>`) — never roll your own hashing.
- **Access token:** short-lived (**5–15 min**), signed HMAC-SHA256 with a key ≥ 32 bytes (or RSA/ECDSA
  when other services must validate). Claims: `sub` (user id), `jti`, `email`/`name`, `role`s — nothing sensitive.
- **Refresh token:** long-lived (7–30 days), cryptographically random (`RandomNumberGenerator.GetBytes(64)`),
  stored **hashed** (SHA-256) in a `RefreshTokens` table (UserId, TokenHash, ExpiresAt, CreatedAt, RevokedAt,
  ReplacedByTokenHash, CreatedByIp).
  - **Rotate on every refresh**; revoke the old one. If a revoked token is reused → revoke the whole family
    (token-theft detection).
  - Browser SPA clients: send refresh token as `HttpOnly; Secure; SameSite=Strict` cookie; access token
    in memory (not localStorage). Mobile/server clients may receive it in the body.
- Endpoints: `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` (revoke); `GET /auth/me`.
- Validate issuer, audience, lifetime and signing key (all `true`); `ClockSkew = TimeSpan.FromSeconds(30)`; `MapInboundClaims = false`.
- **Secure by default:** `FallbackPolicy = RequireAuthenticatedUser()`; mark public endpoints `[AllowAnonymous]`.
- Authorize with **named policies** (`"AdminOnly"`, `"CanManageInventory"`) rather than scattered role strings.
- `ICurrentUser` (Application interface, Api implementation over `IHttpContextAccessor`) — services never read `HttpContext`.
- Rate-limit `login`/`refresh`/`register` with the built-in rate limiter; lock out after repeated failures.
- **Secrets:** signing key and connection strings come from user-secrets (dev) or environment variables /
  a vault (prod). Never committed. Fail at startup if the key is missing or too short (skip only in
  Development/Testing; unit-test the validator with a stub `IHostEnvironment`). When removing a committed secret,
  grep every consumer that silently relied on it (golden tests, an E2E stack running as Production, docker docs)
  and give each its own throwaway key.

### 7a. Security hardening (apply all of these)
- **Rate-limit keys must equal what the endpoint binds.** If a partition key comes from the request body (e.g. the
  login email), parse it the way MVC binds it (case-insensitive) and reject bodies with duplicate/ambiguous keys
  (`JsonSerializerOptions.AllowDuplicateProperties = false` on .NET 10), or `{"email":"x","Email":"victim"}` gets a
  fresh bucket per request. Normalise like Identity (`Normalize().ToUpperInvariant()`). Add a coarser per-IP limit
  alongside any per-account limit. A body-derived key that cannot be read (oversize, malformed) gets the strict limit.
- **Links in emails** come from a configured public base URL, never the request `Host` header (outside Development);
  without the setting, emit a relative link and log a warning.
- **Idempotent replays** that must return a secret (e.g. an order access token stored hashed) keep it sealed (AES-GCM,
  key derived from the client's Idempotency-Key), never in plain text in the stored response.
- **Behind a proxy:** `UseForwardedHeaders` (XForwardedFor + XForwardedProto) first in the pipeline, trusting only
  configured `KnownProxies`/`KnownNetworks` (empty = trust nothing); otherwise all clients share the proxy IP in rate
  limits and `Request.IsHttps` is false. Document the setting in the deployment doc.
- **Cookies:** refresh cookie `Secure` everywhere except plain-http Development; HSTS + HTTPS redirection outside it.
- **Concurrency-safe counters and tokens:** never read-modify-write a security counter (failed logins, PIN
  attempts) — increment atomically (`ExecuteUpdateAsync(s => s.SetProperty(x => x.Count, x => x.Count + 1))`).
  Claim refresh tokens atomically (`UPDATE … WHERE TokenHash = @h AND RevokedAt IS NULL`, 0 rows = reuse) inside
  the same transaction that issues the replacement. Test each with parallel requests.
- **Options:** validate nested option objects too (`ValidateDataAnnotations` does not recurse) and fail at start. A new
  required production setting goes into the test factory's base config in the same change.
- **Layered concurrency guards** (state check + unique row + lock): test each guard alone as the only defence (assert
  every response succeeds, assert dedup row counts) and mutation-check it, or a removed guard stays green.
- Entities with an `xmin` token: lock with a separate `SELECT 1 … FOR UPDATE` (`FromSql` doesn't return `xmin`), then load.
- **Store client IPs safely:** strip the IPv6 zone id and cap to the column length before saving.
- **Dev config never ships:** `appsettings.Development.json` has `CopyToPublishDirectory=Never` and holds no
  secrets; dev keys come from user-secrets or the compose environment.
- **Startup resilience:** retry migrate/seed on transient DB errors (bounded, with backoff) rather than crashing
  when the DB is slow to start; add `GSS Encryption Mode=Disable` to Npgsql connection strings in containers
  unless Kerberos is used.

Reference implementation (token service, atomic rotation, lockout, SPA client): `.claude/wiki/features/jwt-refresh-auth.md`.

## 8. API layer
- Follow the project's existing style (controllers vs minimal APIs). For new projects either is fine;
  minimal APIs with `MapGroup` per feature are the modern default, controllers are fine for large teams.
- Endpoints stay thin: bind → validate → call service → map `Result` to HTTP.
- RESTful routes, plural nouns, versioned (`/api/v1/...`). Correct status codes:
  200/201 (+ `Location`)/204, 400 validation, 401, 403, 404, 409 conflict, 422 business rule if used.
- **Errors as RFC 7807 ProblemDetails** everywhere: `AddProblemDetails()` + a global `IExceptionHandler`;
  map `Result` errors to `TypedResults.Problem(...)` / `ValidationProblem(...)`. Never leak stack traces outside Development.
- Paging on all list endpoints (`page`, `pageSize` with a max), return `PagedResult<T>`.
- **OpenAPI:** built-in `Microsoft.AspNetCore.OpenApi` (`AddOpenApi()` / `MapOpenApi()`) with Scalar UI
  in Development — not Swashbuckle on new projects. Add the Bearer security scheme.
  - String enums: register `JsonStringEnumConverter` in `ConfigureHttpJsonOptions` too (the generator reads those, not
    the MVC `AddJsonOptions`), then check that enum schemas in the snapshot are strings.
  - Commit the document as `backend/openapi/v1.json`, generated at build time on demand
    (`Microsoft.Extensions.ApiDescription.Server`, `dotnet build -p:OpenApiGenerateDocuments=true`), plus a test
    that the live `/openapi/v1.json` equals the snapshot. The frontend generates its types from that file.
  - Build-time generation runs `Program.cs`: skip migrate/seed/secret checks when the entry assembly is
    `GetDocument.Insider`. Strip the .NET 10 `["number","string"]` numeric union with a schema transformer so
    clients get plain `number`.
- Cross-cutting: CORS with an explicit origin list, `UseHttpsRedirection`, HSTS in prod, rate limiting,
  health checks (`/health/live`, `/health/ready` incl. DB), response compression, structured logging
  (built-in `ILogger` with message templates; Serilog/OpenTelemetry if the project wants sinks/tracing).
- Log key events (login success/failure, order/payment creation) — never log passwords, tokens, or secrets.

## 9. Testing
- xUnit + FluentAssertions-style assertions (or Shouldly) + NSubstitute for mocks.
- Unit-test domain logic and services (mock repositories/UoW).
- Integration-test endpoints with `WebApplicationFactory<Program>` against a real database via
  **Testcontainers** (not EF InMemory). Cover auth: 401 without token, 403 wrong role, refresh rotation.
- `dotnet build` and `dotnet test` must pass before reporting a task done — report actual output.

## 10. Checklist before finishing a backend task
- [ ] Layer dependencies respected; no EF entity in an API response
- [ ] Repository interface in Application, implementation in Infrastructure, no `SaveChanges` in repositories
- [ ] Inputs validated; errors returned as ProblemDetails
- [ ] Endpoint authorization correct (fallback policy + `[AllowAnonymous]` / named policies)
- [ ] Migration added if the model changed
- [ ] No secrets in source; new options (including nested ones) validated on start
- [ ] Security hardening (7a) applied to any auth, rate-limit, counter or cookie code touched; parallel-request tests for counters/tokens
- [ ] OpenAPI snapshot regenerated and diffed if the contract may have changed
- [ ] Tests added/updated; build + tests pass
