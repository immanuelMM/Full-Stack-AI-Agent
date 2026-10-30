# Multi-location (branch) data isolation

Status: **implemented** — cafe-pos-system `d04812d` (inventory plan phase 2).

## What it does
- The access token carries a `location_id` claim; `ICurrentLocation` exposes it.
- EF global query filters on every location-scoped entity (`LocationId == CurrentLocationId`); no location = matches
  nothing. Cross-location reads use explicit `IgnoreQueryFilters()` inside repositories only.
- Write guard in `SaveChangesAsync`: new `ILocationScoped` rows get the current `LocationId`; writing to another location
  throws; stock movements are append-only.
- Services check role/scope: other locations' rows are `404`, non-owners acting outside their location `403`,
  location-bound actions in an Owner "All locations" session `400`. Never trust a client-supplied `locationId`.
- Shared catalog with per-location overrides (price, tracking, thresholds). Location switch revokes the refresh token and
  issues a new access token + cookie.

## Reference implementation
- `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/CafeDbContext.cs`, `cafe-pos-system/backend/src/CafePos.Domain/ILocationScoped.cs`,
  `cafe-pos-system/backend/src/CafePos.Application/Common/ICurrentLocation.cs`, `cafe-pos-system/backend/src/CafePos.Application/Features/Inventory/LocationScope.cs`,
  `cafe-pos-system/frontend/src/app/LocationSwitcher.tsx`.
- Tests: `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/IsolationAdversarialTests.cs`,
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/Phase2Tests.cs`, `cafe-pos-system/e2e/tests/isolation.spec.ts`.
- Docs: `cafe-pos-system/docs/architecture.md` ("Multi-location isolation").
