# Signed QR codes + signing-key validation and rotation

Status: **implemented** — IMMAN_HRIS `d4c2e28` (F3 + review fixes).

## What it does
- Employee QR payload `HRISID2:<id>:<sig>`, HMAC-signed with a dedicated `QrSigning:Key` (never derived from the JWT key);
  ids are canonical (digits only, no sign/spaces/leading zeros); compare with fixed-time equality.
- Optional `QrSigning:LegacyKey` verifies only old `HRISID:` cards during a gradual reprint; remove it to retire them.
- `SigningKeys.Resolve` validates all keys at startup in every environment: present outside Development (Development
  generates per-run keys), ≥ 32 bytes, all different, not on a denylist of keys ever published in the repo
  (old committed key, dev/E2E/test keys). Logs which keys are set and only a fingerprint of the (already public) legacy key.

## Reference implementation
- `IMMAN_HRIS/backend/HRIS.Api/Services/SigningKeys.cs`, `IMMAN_HRIS/backend/HRIS.Api/Services/EmployeeQrService.cs`,
  QR endpoint `GET /api/me/qr-token` in `IMMAN_HRIS/backend/HRIS.Api/Controllers/MeController.cs`.
- Tests: `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/QrScanTokenTests.cs` (golden tokens, tampering, legacy),
  `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/SigningKeyTests.cs`,
  `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/ProductionStartupTests.cs`.
- Runbook: `IMMAN_HRIS/docs/deploy/r1-signing-keys.md` (Render: add vars with "Save only", then deploy, check the log line).

## Config
`Jwt__Key`, `QrSigning__Key`, `QrSigning__LegacyKey` (`<old-jwt-key>:employee-qr-v1`, exact, no trailing whitespace).

## Port (any signed, printed or persisted token)
1. Give each purpose its own key + options validated on start; version the payload prefix.
2. Write a golden test of a token produced with a fixed key **before** any change; keep it forever.
3. For rotation, verify old tokens with a legacy key for a limited time instead of breaking printed material.

## Gotchas
- Before rotating any key, list every persisted/printed value derived from it (QR/HMAC signatures, Data Protection
  app name + purpose, hash formats).
- On Render, saving an env var can redeploy the old build with the new key: use "Save only" until the new build ships.
- Removing a committed secret: grep every consumer that relied on it (golden tests, E2E stack running as Production,
  docs) and give each its own throwaway key.
