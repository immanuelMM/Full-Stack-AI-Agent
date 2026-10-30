# Transactional email via an outbox (Resend sender)

Status: **implemented** — beth-online-shop `00a4328` (B2a: outbox, worker, Resend + log senders, order emails).

## What it does
- Use cases insert email rows into an outbox table in the **same transaction** as the business change (checkout), so a
  request never waits on (or fails because of) the email provider.
- `EmailOutboxWorker` (hosted service) sends batches on a timer; a failing tick never stops the loop.
- Sender: Resend HTTP API when `Email:Resend:ApiKey` is set, otherwise a log-only sender (dev/tests). Never SMTP.
- Options validated on start (`From` required with an API key, https base URL, poll/batch ranges).

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Infrastructure/Email/EmailSenders.cs` (`EmailOptions`, `ResendEmailSender`, `LogEmailSender`, validator),
  `beth-online-shop/backend/src/BethShop.Infrastructure/Email/EmailOutboxWorker.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Orders/Emails.cs` (templates),
  `IEmailOutboxRepository` in `beth-online-shop/backend/src/BethShop.Application/Features/Orders/IOrderRepositories.cs`,
  registration in `beth-online-shop/backend/src/BethShop.Infrastructure/DependencyInjection.cs`.

## Config
`Email__From`, `Email__Resend__ApiKey` (secret), `Email__Resend__BaseUrl`, `Email__Worker__PollSeconds`,
`Email__Worker__BatchSize`. See [Resend](../platforms/resend.md).

## Gotchas
- The worker only runs while the app is awake (free hosts sleep): emails go out on the next wake-up.
- Emails are confirmations, not tax invoices (beth decision). Never log full bodies with PII.
