# Ship-date calculator + Philippine phone normaliser

Status: **implemented** — beth-online-shop `00a4328` (domain, golden tests since B0).

## What it does
- `ShipDateCalculator(TimeProvider)`: Manila calendar dates (`DateOnly`); `AddWorkingDays(start, days, workingDays)`
  over the configured working days (Mon-Sat by default; the start day is not counted; 0 days = first working day on or
  after the start). No holiday calendar — staff move a date by hand. `ManilaCalendar` converts instants to Manila dates.
  Tests use `FakeTimeProvider`.
- `PhoneNumber.TryNormalize`: `09171234567`, `9171234567`, `639171234567`, `+63 917 123 4567`, `(0917) 123-4567` →
  `+639171234567`; ignores spaces, dashes, dots, parentheses; rejects landlines and foreign numbers. The E.164 form is
  the key for COD caps and block lists.

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Domain/Scheduling/ShipDateCalculator.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Scheduling/ManilaCalendar.cs`,
  `beth-online-shop/backend/src/BethShop.Domain/Phones/PhoneNumber.cs`, schedule fields in `beth-online-shop/backend/src/BethShop.Domain/ShopSettings.cs`.
- Tests: `beth-online-shop/backend/tests/BethShop.Domain.Tests/ShipDateCalculatorTests.cs` (weekend/Sunday skip, lead 0/1/10),
  `beth-online-shop/backend/tests/BethShop.Domain.Tests/PhoneNumberTests.cs`.
- Frontend date helpers: `beth-online-shop/frontend/src/lib/format.ts`.

## Port
Copy both domain files + tests; no dependencies besides `TimeProvider`. Philippine wall-clock time in a legacy app:
`IMMAN_HRIS/backend/HRIS.Api/Services/PhilippineTime.cs`.
