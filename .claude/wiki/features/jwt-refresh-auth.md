# JWT access + refresh rotation auth (with lockout and a single-flight refresh client)

Status: **implemented** — cafe-pos-system `d04812d` (reference), copied into beth-online-shop `00a4328`.
IMMAN_HRIS still uses a 12 h JWT in `localStorage` (fix F4 planned).

## What it does
- Short access JWT (in memory in the SPA) + random refresh token stored hashed, sent as an HttpOnly cookie scoped to
  `/api/v1/auth`, rotated on every refresh.
- Rotation claims the old token with one conditional UPDATE in the same transaction that inserts its successor; reuse or
  a lost race revokes every session of the user.
- Identity lockout (5 failures / 5 min → `423`), failure counter incremented atomically in SQL.
- SPA client: on 401 refresh once and retry; refresh serialised across tabs with `navigator.locks`; 429/5xx/network on
  refresh keep the session, only 401/403 clear it.

## When to reuse
Any full stack app with staff/admin logins. Copy it rather than re-deriving; the standards (`dotnet-backend-standards`
§7/§7a, `react-frontend-standards` §3) are the rules, this is the code.

## Reference implementation (cafe-pos-system)
- Backend: `cafe-pos-system/backend/src/CafePos.Application/Features/Auth/AuthService.cs`,
  `cafe-pos-system/backend/src/CafePos.Application/Features/Auth/IRefreshTokenRepository.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/Repositories/RefreshTokenRepository.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Auth/JwtTokenService.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Auth/JwtOptions.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Identity/IdentityService.cs`,
  `cafe-pos-system/backend/src/CafePos.Api/Controllers/AuthController.cs`, `cafe-pos-system/backend/src/CafePos.Api/Auth/Policies.cs`,
  `cafe-pos-system/backend/src/CafePos.Api/Http/HttpCurrentUser.cs`.
- Frontend: `cafe-pos-system/frontend/src/lib/apiClient.ts` (`refreshSession`, Web Lock `REFRESH_LOCK`),
  `cafe-pos-system/frontend/src/features/auth/authStore.ts`, `cafe-pos-system/frontend/src/features/auth/ProtectedRoute.tsx`.
- Decision record: `cafe-pos-system/docs/adr/0005-refresh-token-claim-and-web-locks.md`; diagram in `cafe-pos-system/docs/architecture.md`.
- Tests: `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/AuthHardeningTests.cs` (parallel refresh/lockout),
  `cafe-pos-system/backend/tests/CafePos.Application.Tests/AuthServiceTests.cs`, `cafe-pos-system/frontend/src/lib/apiClient.test.ts`,
  `cafe-pos-system/frontend/src/lib/apiClient.multipart.test.ts`.
- beth variant (customer-free admin auth; password change revokes all sessions and signs out):
  `beth-online-shop/backend/src/BethShop.Application/Features/Auth/AuthService.cs`,
  `beth-online-shop/frontend/src/lib/apiClient.ts`, tests `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/AuthTests.cs`,
  `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/AuthHardeningTests.cs`.

## Contract
`POST /api/v1/auth/login`, `/refresh` (cookie, no body), `/logout`, `GET /auth/me`; cafe adds `/auth/switch-location`;
beth adds change-password. Login returns the access token + `Set-Cookie`.

## Config
`Jwt__Key` (≥ 32 bytes; required outside Development, Development generates one per process), `Jwt__Issuer`,
`Jwt__Audience`, `Jwt__AccessTokenMinutes` (cafe 30), `Jwt__RefreshTokenDays` (7), `RateLimiting__Login*`/`Refresh*`.

## Port to a new app
1. Copy the Auth feature folder, `RefreshToken` entity + configuration, token service, Identity service and controller;
   rename namespaces and the cookie name (`<app>_refresh`) and Web Lock name (`<app>-refresh`).
2. Add the migration; wire `AddInfrastructure`/`AddApi`; set the fallback policy.
3. Copy `apiClient.ts` + `authStore.ts`; regenerate types; copy the hardening tests and adjust routes.

## Gotchas
- Admin password reset with `AddIdentityCore` (no token providers): `GeneratePasswordResetTokenAsync` throws. Validate
  with `users.PasswordValidators`, set `PasswordHash = PasswordHasher.HashPassword(...)`, `UpdateAsync`, revoke all
  refresh tokens and clear lockout (beth `IdentityService.ResetPasswordAsync`). Disabling a user revokes refresh tokens;
  never allow disabling an Owner or yourself.
- Cookie is `SameSite=Lax`/`Strict`: SPA and API must be same-site — on a Public Suffix domain that means one service
  ([same-origin deploy](same-origin-single-image-deploy.md)).
- Re-auth dialogs (kiosk exit) must call login outside the shared 401 handler and discard the token.
- Access tokens aren't re-checked against the DB: a deactivated user keeps access until expiry (documented trade-off).
