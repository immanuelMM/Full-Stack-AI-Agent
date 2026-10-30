# Printing (receipts, ID cards) with window.print

Status: **implemented** — cafe-pos-system `d04812d` (receipt auto-print, menu design print sheet), IMMAN_HRIS
`d4c2e28` (ID card sheets, employee résumé).

## What it does
- Browsers can't print silently: "auto-print" = call `window.print()` once per document (guard against StrictMode double
  effects) and keep a visible "Print again" button. Silent printing needs a kiosk browser flag or a local print agent.
- Print CSS is **unlayered** (it needs `!important`), hides the shell, sets `@page` size/margins.

## Reference implementation
- cafe-pos: `cafe-pos-system/frontend/src/features/orders/ReceiptPage.tsx`, `cafe-pos-system/frontend/src/features/orders/ReceiptView.tsx`,
  `cafe-pos-system/frontend/src/features/orders/useReceipt.ts`, `cafe-pos-system/frontend/src/features/pos/PaymentPanel.tsx`
  (done state + auto-print), `cafe-pos-system/frontend/src/styles/print.css`,
  `cafe-pos-system/frontend/src/features/design-studio/PrintSheet.tsx`; tests
  `cafe-pos-system/frontend/src/features/orders/ReceiptView.test.tsx`, `cafe-pos-system/e2e/tests/payment.spec.ts` (stubbed `window.print` call counts).
- IMMAN_HRIS: `IMMAN_HRIS/frontend/src/pages/admin/PrintIdCardsPage.tsx`, `IMMAN_HRIS/frontend/src/components/IdCardFace.tsx`,
  `IMMAN_HRIS/frontend/src/components/CustomIdCard.tsx`, `IMMAN_HRIS/frontend/src/styles/print.css`,
  `IMMAN_HRIS/frontend/src/styles/id-card.css`; test `IMMAN_HRIS/e2e/tests/print.spec.ts` (print-to-PDF stays multi-page).

## Testing
Stub `window.print` with `addInitScript` and assert call counts; check layout with `page.emulateMedia({ media: 'print' })`
or `page.pdf()`.
