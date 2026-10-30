# Cash on delivery (with staff confirmation and anti-abuse limits)

Status: **backend implemented** — beth-online-shop `00a4328` (eligibility, holds, per-phone/email lock), `0a5d0b6`
(48 h auto-cancel sweeper), `bd27ae9` + `fdfd8fe` (B3: staff confirm, ship/deliver/cash-collected/returned, blocklist,
616 tests). Admin UI: F3 (planned).

## Design (beth plan §5.3, §6)
- **Eligibility** (checked in `/cart/quote` with reasons and again in `/checkout`): COD enabled, fulfilment = Delivery,
  zone `CodAllowed`, total incl. shipping + COD fee ≤ `CodMaxTotal` (₱5,000), no made-to-order line with
  `CodAllowed = false` (default for MTO), phone/email not on `CodBlock`, fewer than `CodMaxOpenPerPhone` (2) open COD
  orders for that phone **and** that email.
- **Stock:** in-stock lines reserved until `ConfirmationDueAt` (now + 48 h); staff confirmation clears the expiry so stock
  is held until shipped (consumed) or cancelled/returned (released); late confirmation re-checks and re-reserves (409 if gone).
- **Staff confirmation** by phone/SMS (tap-to-call links, phone history); unconfirmed orders auto-cancel after 48 h (lazy).
- **Money:** Shipped → Delivered → Cash collected (amount must equal total, else `NeedsAttention`) → Completed; dashboard
  shows COD awaiting remittance.
- **Refused/returned:** mark Returned with reason, restock per line, add phone/email to `CodBlock` by default.
- Anti-abuse: COD checkout 3/hour per IP, per-phone cap race-safe via `pg_advisory_xact_lock` on the phone, PH mobile
  number required, audit every transition with the user id. Mention the block list in the privacy notice.

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Application/Features/Orders/QuoteEngine.cs` (eligibility + reasons),
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/CheckoutService.cs` (contact locks, `CodConfirmHours`),
  `beth-online-shop/backend/src/BethShop.Domain/ShopSettings.cs` (COD settings), `beth-online-shop/backend/src/BethShop.Domain/Shipping/ShippingZone.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Orders/OrderEnums.cs`.
- Phone normalisation: [PH ship date + phone](ph-ship-date-phone.md).

## Admin order steps (beth B3)
- One runner for every step (confirm, ship, cash collected, return, cancel, ship date): begin transaction →
  `LockOrderAsync(number)` → `ClearTracking` → reload → step (variant rows `FOR UPDATE` in id order when it touches
  stock) → save → commit → reload for the response. Reference:
  `beth-online-shop/backend/src/BethShop.Application/Features/AdminOrders/AdminOrderService.cs`.
- One state table, `beth-online-shop/backend/src/BethShop.Domain/Orders/OrderStateMachine.cs`, enforced by
  `Order.Transition` for every caller (payment, sweeper, admin); exhaustive from/to test
  `beth-online-shop/backend/tests/BethShop.Domain.Tests/OrderStateMachineTests.cs`. Detail returns `allowedActions`
  so the UI never repeats the rules.
- COD stock leaves the shelf at ship (consume held reservations then); a late confirm re-checks stock (hold lapsed →
  409 `StockUnavailable`); cancel restocks only consumed reservations. Every admin action writes an `AuditEntries` row.

## Gotchas
- Abuse caps (beth `9f52363`): shop-wide unconfirmed-COD count under advisory lock `cod:unconfirmed-cap` and a
  per-variant share of on-hand (min 1), both quote reasons (`ShopCodBusy`, `ItemCodLimit`); client IP stored on the
  order (cleared by retention); bulk `cancel-related` (SameIp/SameContact) cancels each order in its own transaction.
  Late confirm/payment re-checks MTO capacity for the order's day. Shared test fixtures lift the caps; cap tests get
  their own host (`ApiFactory.CreateHost`, `KeepCodCapsKey`).
- Custom (MTO) work made for a fake COD order can't be resold — keep MTO COD off by default.
- Courier COD fees and remittance schedules vary; with no courier API, delivery and remittance are recorded by staff.
