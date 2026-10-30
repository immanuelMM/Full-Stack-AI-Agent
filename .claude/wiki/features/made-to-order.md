# Made-to-order products (lead time, daily capacity, ship dates)

Status: **backend implemented** — beth-online-shop `00a4328` (B1 fields/validation, B2a capacity + estimated ship
date), `bd27ae9` (B3: "preparing" email, staff ship-date change, overdue flag). Admin UI: F3 (planned).

Back-office views need no new tables: `HasMadeToOrder` + `EstimatedShipDate` give "overdue" (Confirmed/Preparing, date
before today in Manila) and "due in 3 days". The sweeper raises a "Ship date passed" segment of `NeedsAttentionReason`
that clears on ship, cancel or a new date and can't be cleared by hand while true. A ship-date change needs a reason and
a date not in the past, and emails the customer (`OrderExpiryService.FlagOverdueShipDatesAsync`,
`AdminOrderService.ChangeShipDateAsync`).

## What it does
- Product `FulfilmentType` = InStock or MadeToOrder. MTO products carry `leadTimeDays` (1-60), optional `dailyCapacity`
  and `maxPerOrder`; their variants never hold stock (API rejects `onHand > 0` / `trackInventory: true`); in-stock
  products reject the MTO fields.
- Checkout locks the MTO product row and checks `qty ≤ MaxPerOrder` and today's committed qty + qty ≤ `DailyCapacity`
  (two shoppers can't both take the last slot); MTO lines create no reservations.
- Estimated ship date per order from the Manila working-day calendar (configured working days, Mon-Sat default) + the
  longest lead time; mixed carts ship together when everything is ready. Shown on product page, cart, emails.
- Public availability subtracts reservations and today's accepted MTO units.

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Domain/Catalog/FulfilmentType.cs`, `beth-online-shop/backend/src/BethShop.Domain/Catalog/Product.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Catalog/ProductVariant.cs`, `beth-online-shop/backend/src/BethShop.Application/Features/Catalog/CatalogValidators.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Catalog/CatalogService.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/QuoteEngine.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Scheduling/ShipDateCalculator.cs`.
- Tests: `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/CatalogAdminTests.cs`,
  `beth-online-shop/backend/tests/BethShop.Application.Tests/CatalogValidatorTests.cs`,
  `beth-online-shop/backend/tests/BethShop.Domain.Tests/ShipDateCalculatorTests.cs`.
- Design: `beth-online-shop/docs/plan/online-shop-plan.md` Decisions #1, §5.1.
