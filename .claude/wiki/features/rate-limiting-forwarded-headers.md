# Rate limiting + forwarded headers

Status: **implemented** — cafe-pos-system `d04812d` (reference), beth-online-shop `00a4328` (adds checkout/quote/lookup
policies). IMMAN_HRIS: approved (F2/F7), not built yet.

## What it does
- Built-in ASP.NET Core rate limiter, fixed windows, per-route policies; `429` + `Retry-After`.
- Login partitioned on client IP + the **bound** email (parsed case-insensitively like MVC, normalised like Identity),
  plus a coarser per-IP limit; duplicate JSON keys rejected (`AllowDuplicateProperties = false`).
- `UseForwardedHeaders` first in the pipeline, trusting only configured `KnownProxies`/`KnownNetworks` (empty = trust
  nothing, middleware not installed); `ForwardLimit` configurable, every unwound hop must be trusted.
- Client IP stored safely (IPv6 zone id stripped, capped to column length).

## Reference implementation
- `cafe-pos-system/backend/src/CafePos.Api/RateLimiting/` — `RateLimitingSetup.cs`, `RateLimitPolicies.cs`,
  `RateLimitingOptions.cs`, `RateLimitKeyCaptureMiddleware.cs`.
- `cafe-pos-system/backend/src/CafePos.Api/Http/ForwardedHeadersSetup.cs`, `cafe-pos-system/backend/src/CafePos.Api/Http/ClientIp.cs`.
- Tests: `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/ForwardLimitTests.cs`,
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/AuthHardeningTests.cs`, `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/ReviewFixTests.cs`.
- Decision: `cafe-pos-system/docs/adr/0006-rate-limit-partitions-and-proxy-trust.md`; ops guide `cafe-pos-system/docs/deployment.md`
  ("Behind the ingress", "Rate limiting").
- beth checkout policies: `beth-online-shop/backend/src/BethShop.Api/RateLimiting/RateLimitingOptions.cs`.

## Config
`RateLimiting__Enabled` (never false in prod), `RateLimiting__<Policy>__PermitLimit` / `__WindowSeconds`
(cafe defaults: Login 10/60 per IP+email, LoginPerIp 50/60, Refresh 30/60, SwitchLocation 30/60 per user, TimeclockPunch
10/60 per IP+staff), `ForwardedHeaders__KnownProxies__N`, `ForwardedHeaders__KnownNetworks__N`, `ForwardedHeaders__ForwardLimit`.

## Port
Copy the `RateLimiting/` folder + `ForwardedHeadersSetup.cs` + `ClientIp.cs`, rename policies to your routes, copy
`ForwardLimitTests` and the parallel login tests; document every key in `docs/deployment.md`.

## Gotchas
- Test hosts have no socket (`RemoteIpAddress` null): an `IStartupFilter` sets it from a test header (beth
  `TestClientIpFilter`, `client.FromIp("203.0.113.5")`). TestServer doesn't enforce `[RequestSizeLimit]` — assert the
  attribute by reflection. Body-derived partitions fail closed (fixed bucket) on chunked/oversize/malformed bodies.
- Without forwarded headers behind a TLS proxy: every client shares the proxy IP (one attacker locks out all logins)
  and HTTPS redirection loops.
- Never trust `0.0.0.0/0`, `::/0`, a public or CDN range. Find the proxy's real source address once per environment:
  deploy with no trust list, log in, read the stored client IP, then trust that network and re-check.
- Shared office/kiosk NAT shares per-IP budgets: raise `LoginPerIp`/`Refresh` for many tablets.
- Counters are in memory: per replica, reset on restart. E2E stacks set `RateLimiting__Enabled=false`.
