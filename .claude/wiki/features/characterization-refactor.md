# Characterization-first refactor of a live app with real data

Status: **implemented (phase A)** — IMMAN_HRIS `d4c2e28` (M0-M2); cafe-pos-system did its refactor with an upgrade test
from a pre-refactor dump.

## What it does
1. **Baseline (M0):** production `pg_dump -Fc` + restore test by the user; golden OpenAPI/Swagger, schema-only dump,
   screenshots of every screen at each size, committed under `docs/plan/baseline/`.
2. **Characterization tests (M1)** on the unmodified code: every endpoint's status + body as golden files, auth matrix,
   golden invariants for anything derived from secrets (QR tokens, password/PIN hashes from the old build, Data
   Protection round trip), backup round trip incl. a golden backup file, migrations from empty → schema equals golden.
3. **Upgrade in place (M2)** with the suites unchanged; `dotnet ef migrations has-pending-model-changes` must report none
   (EF 9+ throws on model drift at startup `Migrate()`).
4. **Rehearsal** of each model-touching milestone on a restored production dump in a throwaway container (own port,
   deleted afterwards — it holds PII): migration history, row counts, schema diff, real logins, a printed QR still scans.
5. Restructure only after this is green; snapshot unchanged per commit.

## Reference implementation
- Plan: `IMMAN_HRIS/docs/plan/refactor-plan.md` §5-6 (milestones, migration safety procedure).
- Golden recorder: `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/Infrastructure/GoldenRecorder.cs`,
  golden files `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/Golden/`,
  `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/GoldenInvariantTests.cs`,
  `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/MigrationAndStartupTests.cs`,
  `IMMAN_HRIS/backend/tests/Hris.Api.IntegrationTests/BackupTests.cs`.
- cafe-pos upgrade test: `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/UpgradeFromPreRefactorTests.cs` +
  `cafe-pos-system/backend/tests/CafePos.Api.IntegrationTests/Fixtures/pre-refactor-m3.sql`.

## Gotchas (.NET 8 → 10)
- Npgsql 10 returns `DateOnly` for `date` columns from raw ADO reads (`ExecuteScalar`, readers): `Convert.ChangeType`
  helpers break.
- Drop references the framework now ships (NU1510); fix MSB3277 by aligning EF package versions.
- Use a `dotnet-ef` matching the EF major (temp `--tool-path`).
- Ask early whether production Postgres is on a free plan (expiry, no backups) — it changes the order of work.
