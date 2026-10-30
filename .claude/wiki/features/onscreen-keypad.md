# On-screen keypad for money and PIN entry

Status: **implemented** — cafe-pos-system `d04812d` (cash tendered), IMMAN_HRIS `d4c2e28` (employee PIN login).

## What it does
A 3×4 keypad of ≥ 56px keys that edits a real, labelled `<input>`. On `(pointer: coarse)` the input gets
`inputMode="none"` and no autofocus, so the OS keyboard never covers the screen; on desktop the input stays typeable.
An `extraKey` slot holds `.` (money), `00` or nothing (PIN).

## Reference implementation
- `cafe-pos-system/frontend/src/components/Keypad.tsx` (`Keypad({ label, onKey, extraKey, disabled })`), used in
  `cafe-pos-system/frontend/src/features/pos/PaymentPanel.tsx`; test `cafe-pos-system/frontend/src/components/Keypad.test.tsx`;
  E2E `cafe-pos-system/e2e/tests/payment.spec.ts`.
- `IMMAN_HRIS/frontend/src/components/Keypad.tsx`, used in `IMMAN_HRIS/frontend/src/pages/LoginPage.tsx`; test
  `IMMAN_HRIS/frontend/src/components/Keypad.test.tsx`; E2E `IMMAN_HRIS/e2e/tests/u5-login.spec.ts` (keypad on `phone`).

## Port
Copy `Keypad.tsx` + its CSS block in `components.css`; keep the real input as the source of truth (form libraries and
`getByLabelText` keep working); switch `inputMode` with `useMediaQuery('(pointer: coarse)')`.

## Gotchas
- Check the keypad fits at 375×667 together with the primary button (a hidden bottom row once passed every unit test).
- Phone/tablet Playwright projects need `hasTouch: true, isMobile: true` or the coarse-pointer path is never exercised.
