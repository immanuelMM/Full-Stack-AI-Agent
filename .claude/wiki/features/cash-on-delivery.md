# Cash on delivery (with staff confirmation and anti-abuse limits)

Status: **partly implemented** — beth-online-shop `00a4328`: eligibility rules in quote + checkout, held reservations,
per-phone/email advisory lock. **Planned:** staff confirmation, 48 h auto-cancel sweeper, ship/deliver/cash-collected/
returned flow, `CodBlock` admin (B3/F3).

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

## Gotchas
- Custom (MTO) work made for a fake COD order can't be resold — keep MTO COD off by default.
- Courier COD fees and remittance schedules vary; with no courier API, delivery and remittance are recorded by staff.
