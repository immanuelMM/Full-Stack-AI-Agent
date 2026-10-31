# Render (render.com)

Used by: cafe-pos-system (live, free, created 2026-10-29), IMMAN_HRIS (free web + free Postgres), beth-online-shop
(planned free demo). Reference: `cafe-pos-system/render.yaml`, `cafe-pos-system/docs/deployment.md` ("Render"),
sources checked 2026-10-29.

## Free plan limits (verify before choosing features)
- Web service sleeps after 15 min idle (the SPA too, if served by it); ~1 min cold start. In-memory rate limits reset.
- Free Postgres **expires 30 days after creation** (+14 days grace, then deleted), 1 GB, no backups — remind the user to
  upgrade or `pg_dump` before day 30. A recreated DB is empty (bootstrap vars needed again).
- No `preDeployCommand`, no persistent disk, no scaling; 750 instance hours/month per workspace.
- **Outbound SMTP blocked** (ports 25/465/587, since Sep 2025): send email over an HTTP API ([Resend](resend.md)).
- No persistent disk on free (and disks block zero-downtime deploys): store uploads in object storage ([R2](cloudflare-r2.md)).

## Domains and networking
- `onrender.com` is on the **Public Suffix List**: two services are different *sites* (refresh cookie not sent, CORS
  needed). Deploy **one** web service serving API + SPA ([same-origin deploy](../features/same-origin-single-image-deploy.md)).
- Never put a proxy/rewrite service in front of the API (every user shares its IP → shared rate limits).
- Never hard-code the `*.onrender.com` hostname: Render may append a suffix (cafe got `cafe-pos-vjc0`), and a taken name
  points at a stranger's service.
- TLS ends at Render's load balancer (plain HTTP to the container). Trust forwarded headers from private ranges only
  (`10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, fc00::/7`, `ForwardLimit=1`); the LB source address is not
  documented, so run the post-deploy check (stored client IP must equal the user's public IP), then narrow the range.
  The check for cafe-pos was still pending on 2026-10-29.
- Database internal-only (`ipAllowList: []`); for `psql`, temporarily allow your `/32` in the dashboard, use the External
  URL, remove the rule. Internal URL works only within one region; internal TLS is self-signed (`verify-*` unsupported).

## Blueprint (`render.yaml`)
- Render reads it **from GitHub**: commit and push (with the user's OK) before giving dashboard steps; validate against
  `https://render.com/schema/render.yaml.json`.
- `fromDatabase.connectionString` → `DATABASE_URL` (`postgresql://…`; parse it in the app). `generateValue: true` for
  `Jwt__Key`. `sync: false` vars are prompted only at Blueprint creation. `autoDeployTrigger: checksPass`, `buildFilter`
  paths, `healthCheckPath: /health/live` (not `/ready`: a DB blip would restart the app). Region and Postgres major are
  immutable.

## Env var steps for the user
- Dashboard → service → Environment. Give exact example values (IANA zone `Asia/Manila`, VAT `12`, secrets from
  `openssl rand -base64 48`). Values are saved exactly as typed (no trailing spaces).
- "Save, rebuild and deploy" redeploys the **current** build: when new vars must only apply to a new build, use
  "Save only", then deploy the new build.
- Bootstrap vars: remove only after the user confirms they logged in.

## Paid
Paid DB (no expiry, backups) + paid service (no sleep, `preDeployCommand` for a migration bundle, then
`Database__MigrateOnStartup=false`). Steps: `cafe-pos-system/docs/deployment.md` ("Upgrading to paid").

## Public URL
- Render sets `RENDER_EXTERNAL_URL` (https) on web services: let the app fall back to it outside Development instead
  of making the user type a guessed URL (explicit setting wins). Settings that need the URL after creation (webhook
  secrets) get a placeholder at creation, then one "Save, rebuild and deploy" after registering. That Render sets it on
  free services is still unconfirmed (beth smoke-tests the fallback only).
