# PayMongo (Philippine payments: GCash, Maya, cards, QR Ph)

Status: **implemented** — beth-online-shop `0a5d0b6`, `99b97c8`, `2cb1e97` (B2b, verified by the lead: 528 tests green).
Built against the docs and a WireMock fake only — no test keys yet, nothing called live. Facts below were read from the
docs on 2026-10-30; items under "Still assumed" must be checked with a test-mode payment and kept as golden tests.

## Docs access
Doc pages may fetch blank: read `https://docs.paymongo.com/llms.txt` and the `.md` URLs it lists.

## Confirmed from the docs
- **Create:** `POST /v2/checkout_sessions`, Basic auth (secret key as username); the page URL is
  `data.attributes.checkout_url`. Send `reference_number`, server-priced `line_items`, `payment_method_types`,
  `success_url`/`cancel_url`, and an `Idempotency-Key` (= Payment.Id).
- **Retrieve:** `GET /v1/checkout_sessions/{id}` → `attributes.status` (`active`|`expired`) and `payments[]` with
  `attributes.status=paid`, `amount`, `currency`, `paid_at`, `source.type`.
- **Expire:** `POST /v1/checkout_sessions/{id}/expire` → 400 if already expired, paid or mid-payment.
- **Sessions never expire on their own** and no event is sent on expiry: the shop must call expire when its reservation
  window ends. Payments on an expired session are rejected.
- **Amounts** are integer centavos (10000 = ₱100; 49900 + fee 760 → payment 50660).
- **Webhook signature:** header `Paymongo-Signature: t=…,te=…,li=…`; HMAC-SHA256(webhook secret, `"{t}.{rawBody}"`),
  hex, compared with `te` (test) or `li` (live) via `CryptographicOperations.FixedTimeEquals`, on the raw body before
  parsing. Skip the timestamp age check: retries replay the original `t`.
- **Webhook envelope:** `data.id` (`evt_…`), `data.attributes.{type, livemode, data}`; event `checkout_session.payment.paid`.
  Up to 12 retries (the "3" on one page is stale).
- `payment_method_types` values seen: `gcash`, `paymaya`, `grab_pay`, `card`, `qrph`, `atome` (beth default: gcash,
  paymaya, card, qrph). A QR Ph code's own 30-min validity does not expire the session.
- `Idempotency-Key`: create only, valid 24 h, different parameters under the same key are rejected; not on retrieve/expire.
- Webhook reply: 200–209 with a JSON body within 30 s; retries use exponential backoff. At most one paid payment per
  session; retrieve's `payments[]` has the same shape as the webhook's (`paid_at` in unix seconds).

## Still assumed
Retrieve/expire work on v2-created sessions; `paid_at` present in the webhook payload; signature hex case; `?t=` survives
in `success_url`; maximum line-item name length. The Hosted Checkout docs page shows a flatter `send.webhook` shape without
an event id — confirm the real envelope on the first test-mode event.

## Reference implementation (beth-online-shop)
- Client: `beth-online-shop/backend/src/BethShop.Infrastructure/Payments/PayMongoClient.cs`, options
  `beth-online-shop/backend/src/BethShop.Infrastructure/Payments/PayMongoOptions.cs` (validated at startup outside Development).
- Webhook: `beth-online-shop/backend/src/BethShop.Api/Controllers/WebhooksController.cs` (128 KB limit, outside auth
  fallback and rate limits, not in the OpenAPI contract), parsing/signature
  `beth-online-shop/backend/src/BethShop.Application/Features/Payments/PayMongoWebhook.cs`.
- One payment-apply path for webhook, reconcile-on-read and sweeper:
  `beth-online-shop/backend/src/BethShop.Application/Features/Payments/PaymentApplier.cs`, `PaymentService.cs`; sweeper
  `beth-online-shop/backend/src/BethShop.Infrastructure/Payments/OrderSweeperWorker.cs` (every 60 s). Recipe on
  [idempotent checkout](../features/idempotent-checkout-reservations.md).
- `POST /api/v1/orders/{number}/pay` (`X-Order-Token`) → `{checkoutUrl, expiresAt}`; 409 `AlreadyPaid` |
  `PaymentWindowClosed` | `PaymentInProgress` | `NotOnlineOrder`; 503 when PayMongo is unreachable.

## Testing (copy for any hosted-session provider)
- `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/FakePayMongo.cs`: WireMock.Net callbacks over a session
  dictionary — idempotent create by Idempotency-Key, retrieve with a paid payment, expire answering 400 when expired/paid,
  failure switches, a signed `PaidWebhook` builder.
- `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/PaymentTestSupport.cs`: xUnit collection fixture with its
  own fake and factory. Golden signature tests: `beth-online-shop/backend/tests/BethShop.Application.Tests/PayMongoWebhookTests.cs`.
- WireMock.Net notes: responses are `ResponseMessage` with `BodyData`; request headers are
  `IDictionary<string, WireMockList<string>>` (look up case-insensitively); raw JSON with `}}` needs `$$"""`.
- Never call real PayMongo from CI; E2E uses a stub server.

## Wallet returns from in-app browsers
Shoppers from Facebook/Messenger pay in the GCash/Maya **apps**, and the return often opens a **different browser** with
empty local state: the order/return page must work from the URL (`number` + token) alone.

Unknown-shape events are ignored with a warning and a 200; if the real test delivery uses the flat envelope, adjust the
event parser. The golden signature vector was computed from the documented algorithm, not a real delivery.

## Keys and modes
- `PayMongo__SecretKey` (`sk_test_…` / `sk_live_…`) and `PayMongo__WebhookSecret` (`whsk_…`, shown when the webhook
  endpoint is created): secrets, required outside Development.
- `PayMongo__LiveMode` (default false; must match the key prefix or startup fails; picks `te` vs `li`),
  `PayMongo__BaseUrl` (default `https://api.paymongo.com`), `PayMongo__TimeoutSeconds` (10).
- `Seo__PublicBaseUrl` is required outside Development: PayMongo returns the shopper there and emails link to it.
- Register the webhook for `checkout_session.payment.paid` at `https://<host>/api/v1/webhooks/paymongo`; one endpoint
  and one secret per mode. On a sleeping free host, PayMongo retries plus reconcile-on-read cover the cold start.

Demo = test-mode keys; going
live = live keys + a new live webhook (new secret). Webhooks need a public HTTPS URL: in dev use a tunnel
(`cloudflared`) or post locally signed fake events. Refunds via the PayMongo dashboard in the MVP. Account activation
needs business documents — apply early.

## Dashboard (docs, 2026-10-31; not yet tried on a real account)
- Test keys exist from sign-up, before activation (Settings > Product Settings > Developers, or Developer Tools > API Keys).
- Webhooks: Developer Tools > Webhooks > Add Endpoint; HTTPS domain only (IP literals → 400); the secret shows only
  after saving. Test and live modes each have their own endpoint and secret (mode switch in the header).
- Live methods are activated per method (Settings > Payment Methods > Request Activation); cards and GCash need a
  registered business type.
