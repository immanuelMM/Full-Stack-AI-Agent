# beth-online-shop

Reflects app commit `5cf759c` (2026-10-30: B0–B2b verified — 528 backend tests; F0–F2 verified — 153 Vitest, E2E at 5 viewports; B3 admin orders in progress).
Paths are relative to `C:\Users\merin\AI\Agentic-fullstack-web-dev\`.

## Purpose
Philippine online shop (PHP, `en-PH`, `Asia/Manila`): mixed catalogue of in-stock goods (up to 2 options) and
made-to-order items, guest checkout with emailed order links, PayMongo hosted checkout (GCash, Maya, cards, QR Ph) and
cash on delivery with staff confirmation, flat-rate shipping zones + pickup, Owner/Staff admin. Demo first on Render free.

## Stack
- .NET 10, EF Core 10 + Npgsql, FluentValidation, Identity, SkiaSharp 4.154 (+ `NativeAssets.Linux.NoDependencies`),
  AWSSDK.S3 4.0 (R2), PostgreSQL 16 (+ `pg_trgm`).
- React 19.3, Vite 8.3, React Router 7.18, TanStack Query 5, RHF 7 + Zod 4, Zustand 5, openapi-typescript + openapi-fetch.
- Copied from cafe-pos: layering, auth/refresh, rate limiting, forwarded headers, SPA hosting, tokens/shell structure.

## Layout
```
backend/   BethShop.slnx, src/BethShop.{Domain,Application,Infrastructure,Api}, tests/BethShop.{Domain,Application}.Tests,
           tests/BethShop.Api.IntegrationTests, openapi/v1.json
frontend/  src/{app (StoreShell, AdminShell),api,components,features,lib,styles,test}
e2e/       playwright.config.ts (no-backend harness), scripts/serve-preview.mjs, support/{api,checks}.ts, tests/screens.spec.ts
docs/plan/online-shop-plan.md, docker-compose.yml (db on :5434)
```

## Status (plan §8)
- Done: B0 scaffold/auth/settings/ship-date/phone, F0 shells + harness, B1 catalog/images/zones/SEO, B2a quote +
  checkout (online + COD) + order tracking + email outbox (tests "follow in the next commit").
- In progress / planned: F1 storefront, Q1, B2b (PayMongo client, webhook, reconcile, sweeper), F2, Q2, B3 admin orders,
  F3, Q3, review, D1 Render demo, docs.

## Key decisions (plan "Decisions", 2026-10-30)
- Mixed catalogue incl. made-to-order (no stock, optional daily cap + max per order, lead time, estimated ship date);
  mixed carts ship together; MTO lines skip reservations.
- PayMongo hosted checkout; COD yes (staff confirmation, eligibility, anti-abuse); no manual transfers.
- Guest only; 4 flat-rate zones + free-shipping threshold + pickup; 30-min reservations; Owner + Staff.
- Resend email; Cloudflare R2 images; Render free demo then paid; custom domain before launch; PII anonymised after
  5 years; rate limits now, Turnstile if abused; refunds via PayMongo dashboard.

## Run and test
- `docker compose up -d --wait db`, then `cd backend && dotnet run --project src/BethShop.Api` (:5090, Scalar `/scalar/v1`).
- `cd backend && dotnet test` (Testcontainers, or `TEST_PG_CONNECTION`).
- Frontend: lint/build/test/format:check. E2E harness: `cd e2e && npm run screens:<project>` (builds into
  `dist-e2e`, `vite preview` on :4175, API fulfilled by `context.route`).

## PH address data (PSGC)
`beth-online-shop/frontend/scripts/build-psgc.mjs` builds `frontend/src/features/checkout/psgc.json` (82 provinces,
1,634 cities) from `https://psgc.gitlab.io/api/{provinces,cities-municipalities}.json`. Use `psgc10DigitCode` (the
9-digit `code` differs). Metro Manila has no province: list it under NCR `1300000000` (in the default zone); City of
Isabela and City of Cotabato map to Basilan and Maguindanao. Checkout is a lazy route so the JSON stays out of the main
bundle; the province select lists only provinces present in `/shipping/zones`.

## Features implemented here
- [JWT + refresh auth](../features/jwt-refresh-auth.md) (password change revokes sessions) ·
  [Clean Architecture backend](../features/clean-architecture-backend.md) · [OpenAPI contract](../features/openapi-contract.md)
- [Image upload pipeline](../features/image-upload-pipeline.md) · [SEO meta + sitemap](../features/seo-meta-sitemap.md) ·
  [PH ship date + phone](../features/ph-ship-date-phone.md)
- [Idempotent checkout + reservations](../features/idempotent-checkout-reservations.md) ·
  [Cash on delivery](../features/cash-on-delivery.md) · [Made-to-order](../features/made-to-order.md) ·
  [Email outbox](../features/email-outbox.md)
- [E2E harness](../features/e2e-playwright-harness.md) (no-backend screenshots) · [Touch UI shell](../features/touch-ui-shell.md)
- Platforms: [PayMongo](../platforms/paymongo.md), [Resend](../platforms/resend.md), [Cloudflare R2](../platforms/cloudflare-r2.md),
  [Render](../platforms/render.md)
