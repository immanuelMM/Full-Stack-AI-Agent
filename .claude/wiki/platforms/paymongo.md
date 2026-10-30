# PayMongo (Philippine payments: GCash, Maya, cards, QR Ph)

Status: **planned** — beth-online-shop B2b (design in `beth-online-shop/docs/plan/online-shop-plan.md` §5.2, §5.4, §6, §7).
Nothing below is verified in code yet; items marked *unconfirmed* must be checked with a test-mode event and kept as
golden tests.

## Docs access
Doc pages may fetch blank: read `https://docs.paymongo.com/llms.txt` and the `.md` URLs it lists.

## Hosted Checkout Sessions (chosen)
- Create (v2 endpoint recommended for new integrations; v1 retrieve/expire) via a typed `HttpClient`, no SDK.
  Send `reference_number = order number`, server-priced `line_items`, enabled `payment_method_types`,
  `success_url`/`cancel_url` = `/order/{number}?t={token}`, and an `Idempotency-Key` (= Payment.Id).
- Create the session **after** the order commit; on failure the order stays PendingPayment and the client can retry `/pay`.
- Expire the session when the reservation expires so a stale one can't be paid.
- Amounts are integer centavos (`decimal * 100`). *Unconfirmed:* docs only imply centavos — confirm with a ₱1.00 test.
- Hosted checkout keeps card data off our pages (SAQ A-like). Never embed card fields; the public key isn't needed.

## Webhook `checkout_session.payment.paid`
- Verify the signature against the **raw body** before parsing: header `t=…,te=…,li=…`; HMAC-SHA256(webhookSecret,
  `"{t}.{rawBody}"`) compared with `li` (live) or `te` (test) using `CryptographicOperations.FixedTimeEquals`.
  *Unconfirmed:* exact string-to-sign.
- Dedup by event id (unique insert → already processed → 200). Check amount + currency equal the order total.
- Respond 200 well within 30 s; queue emails. Retries: up to 12 per one docs page, 3 per another — be idempotent.
- No rate limit on the webhook (signature-gated). Never log full bodies (event id + type only).
- The return URL is not proof of payment: poll the order and reconcile by retrieving the session if the webhook is late
  (cold start). *Unconfirmed:* which retrieve fields expose payment status.

## Wallet returns from in-app browsers
Shoppers coming from Facebook/Messenger pay in the GCash/Maya **apps**, and the return often opens a **different
browser** with empty local state: the order/return page must work from the URL (`number` + token) alone.

## Keys and modes
`PayMongo__SecretKey`, `PayMongo__WebhookSecret` (secrets). Demo = test-mode keys; going live = live keys + a new live
webhook (new secret). Webhooks need a public HTTPS URL: in dev tunnel (`cloudflared`) or post locally signed fake events.
Refunds via the PayMongo dashboard in the MVP; QR Ph refunds have their own rules.

## Testing
Never call real PayMongo from CI: WireMock.Net in integration tests, a stub server in E2E.
