# Idempotent checkout + stock reservations

Status: **implemented** — cafe-pos-system `d04812d` (order completion with `Idempotency-Key` + atomic stock decrement);
beth-online-shop `00a4328` (B2a: full checkout with reservations; its tests were not yet committed at that commit —
check `git log` before relying on them). PayMongo payment side: planned (B2b, [PayMongo](../platforms/paymongo.md)).

## What it does
- Client sends an `Idempotency-Key` header (new UUID per attempt). The server stores an `IdempotencyRecord`
  (scope, key, request hash, status, response, TTL 24 h): same key + same body → replay the stored response; same key
  + different body → `422`; a key still in flight → `409` "retry shortly".
- **The client never sends prices**; the server re-prices from the DB (`/cart/quote` and again inside `/checkout`).
- beth checkout is one transaction with a fixed lock order so concurrent checkouts can't deadlock: advisory lock on the
  idempotency key → advisory locks on the contact (phone, email) → `SELECT … FOR UPDATE` products of MTO lines, then
  variants of in-stock lines, each ordered by Id → recompute the quote from committed data → insert order, items,
  reservations (in-stock lines only), payment row.
- **Lazy expiry:** availability = `OnHand − active (unexpired, unreleased) reservations`, so correctness never depends on
  a background job (free hosts sleep); a sweeper only tidies statuses.
- Order access for guests: random 32-byte token, stored as SHA-256 hash; the URL `/order/{number}?t={token}` alone
  works (no local state); the token is AES-GCM-sealed under a key derived from the Idempotency-Key so a retry can return
  it while the DB alone cannot reveal it.
- cafe-pos: completing an order decrements stock with a conditional UPDATE per ingredient + `StockMovement` rows and
  records payment + idempotency record in one transaction.

## Reference implementation
- beth: `beth-online-shop/backend/src/BethShop.Application/Features/Orders/CheckoutService.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/QuoteEngine.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/IOrderRepositories.cs` (`ICheckoutRepository` lock methods),
  `beth-online-shop/backend/src/BethShop.Infrastructure/Persistence/Repositories/OrderRepository.cs` (advisory + row locks),
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/TokenSealer.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Orders/OrderAccessToken.cs`, `beth-online-shop/backend/src/BethShop.Domain/Orders/Order.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Orders/Money.cs`, `beth-online-shop/backend/src/BethShop.Api/Controllers/OrdersController.cs`,
  `beth-online-shop/backend/src/BethShop.Api/Http/CheckoutProblems.cs`, `beth-online-shop/backend/src/BethShop.Api/Http/OrderLinks.cs`.
- cafe-pos: `cafe-pos-system/backend/src/CafePos.Application/Features/Orders/OrderService.cs` (`CompleteAsync`),
  `cafe-pos-system/backend/src/CafePos.Domain/IdempotencyRecord.cs`, `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/Repositories/OrderRepository.cs`,
  `cafe-pos-system/backend/src/CafePos.Infrastructure/Persistence/Repositories/StockRepository.cs`; tests
  `cafe-pos-system/backend/tests/CafePos.Application.Tests/OrderServiceTests.cs`, `cafe-pos-system/e2e/tests/checkout.spec.ts`;
  client UUID `cafe-pos-system/frontend/src/lib/uuid.ts`.
- Design: `beth-online-shop/docs/plan/online-shop-plan.md` §5.1-5.2, §6 (concurrency tests list).

## Endpoints (beth)
`POST /api/v1/cart/quote`, `POST /api/v1/checkout` (header `Idempotency-Key`), `GET /api/v1/orders/{number}?t=`,
`POST /api/v1/orders/lookup`.

## Tests to copy (parallel requests)
Two checkouts for the last unit (exactly one wins); last MTO capacity slot; same `Idempotency-Key` twice (one order);
COD per-phone cap race; webhook replay (one stock movement).

## Gotchas
- Lock in one global order (keys, then contacts, then products, then variants, each sorted) or concurrent checkouts deadlock.
- Return pages must work from the URL token alone: wallet apps return into a different browser.
- Show only masked PII on token-accessed pages (the token sits in history and provider records).
