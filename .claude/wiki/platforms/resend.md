# Resend (transactional email over HTTPS)

Status: sender **implemented** in beth-online-shop `00a4328` (not yet exercised against the real service); account and
domain setup planned for D1.

- Why: Render free blocks outbound SMTP; use an HTTP email API on any PaaS.
- Free tier (per beth plan, Oct 2026): 3,000 emails/month, 100/day. Needs a **verified sender domain** (DNS records) —
  plan it together with the custom domain.
- API: `POST https://api.resend.com/emails` with `Authorization: Bearer <key>` and JSON `{ from, to[], subject, html, text }`.
- Config: `Email__Resend__ApiKey` (secret, host env var), `Email__From` (address on the verified domain).
- Implementation and outbox pattern: [email outbox](../features/email-outbox.md).
