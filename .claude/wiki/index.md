# Knowledge base (LLM wiki)

What has been built in this workspace and how, so a new app reuses it instead of re-researching or re-deriving it.
Standards (rules) live in `.claude/agents/` and `.claude/skills/`; this folder holds facts, reference files and recipes.

## How to use
1. Before planning or building, read this index and every page that matches the task; cite the page in the plan.
2. Reuse: copy the **reference implementation** files listed on the page, then adapt names — don't re-research a
   covered feature or platform.
3. Research only the gaps; record new findings as lessons whose `target:` is a wiki page.
4. After each verified milestone, the lead updates the app page (status, commit) and adds/updates feature pages.
5. Paths are relative to `C:\Users\merin\AI\Agentic-fullstack-web-dev\`; each page names the app commit it reflects —
   check `git log` in the app if it is old.

## Apps
- [cafe-pos-system](apps/cafe-pos-system.md) — multi-location cafe POS, live on Render; the reference layout for new full stack apps.
- [IMMAN_HRIS](apps/IMMAN_HRIS.md) — live HRIS with QR attendance/kiosk; read for refactoring an existing app with real data.
- [beth-online-shop](apps/beth-online-shop.md) — PH online shop (in progress); read for e-commerce, payments, COD, images, SEO.

## Features
- [JWT + refresh rotation auth](features/jwt-refresh-auth.md) — any app with logins (backend + Web Locks client).
- [Clean Architecture backend](features/clean-architecture-backend.md) — scaffolding a new .NET backend.
- [OpenAPI contract](features/openapi-contract.md) — snapshot, contract test, generated TS types, CI drift check.
- [Touch UI shell](features/touch-ui-shell.md) — responsive shell, tokens, CSS layers, touch sizes (cafe-pos style).
- [On-screen keypad](features/onscreen-keypad.md) — money or PIN entry on tablets/phones.
- [E2E harness](features/e2e-playwright-harness.md) — isolated stack, 5 viewports, layout/axe helpers, screenshots, fake camera.
- [Rate limiting + forwarded headers](features/rate-limiting-forwarded-headers.md) — login limits, proxy trust.
- [Same-origin single-image deploy](features/same-origin-single-image-deploy.md) — API serves SPA, DATABASE_URL, owner bootstrap.
- [GitHub Actions CI](features/github-actions-ci.md) — workflow jobs and CI gotchas.
- [Signed QR codes](features/signed-qr-codes.md) — HMAC tokens, key validation, rotation with a legacy key.
- [QR attendance + kiosk](features/qr-attendance-kiosk.md) — camera scanning, kiosk mode with re-auth exit.
- [Idempotent checkout + reservations](features/idempotent-checkout-reservations.md) — orders, stock, Idempotency-Key, lock order.
- [Cash on delivery](features/cash-on-delivery.md) — COD eligibility, staff confirmation, anti-abuse (partly planned).
- [Made-to-order](features/made-to-order.md) — lead times, daily capacity, ship dates.
- [PH ship date + phone](features/ph-ship-date-phone.md) — working-day calculator, PH mobile normaliser.
- [Image upload pipeline](features/image-upload-pipeline.md) — SkiaSharp re-encode, EXIF, local/R2 storage.
- [SEO meta + sitemap](features/seo-meta-sitemap.md) — link previews for an SPA without SSR.
- [Email outbox](features/email-outbox.md) — transactional email without blocking requests.
- [Printing](features/printing.md) — receipts and ID cards with window.print.
- [Multi-location isolation](features/multi-location-isolation.md) — per-branch data with EF query filters.
- [Characterization-first refactor](features/characterization-refactor.md) — upgrading/restructuring a live app safely.

## Platforms
- [Render](platforms/render.md) — free plan limits, Public Suffix List, Blueprint, env var steps, DB expiry.
- [PayMongo](platforms/paymongo.md) — PH payments, hosted checkout, webhooks, wallet returns (planned).
- [Resend](platforms/resend.md) — HTTP email API.
- [Cloudflare R2](platforms/cloudflare-r2.md) — S3-compatible image storage.
- [GitHub](platforms/github.md) — repos, the user runs git network commands, no `gh`.
- [Windows dev machine](platforms/windows-dev-machine.md) — low RAM, 260-char paths, heredocs, npm quirks, ports.
- [Docker Desktop](platforms/docker-desktop.md) — dev stack isolation, GSS, compose defaults.
