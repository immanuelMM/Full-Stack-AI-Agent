# Docker Desktop

- Must be running for Testcontainers, compose stacks and image builds; `preflight.sh` reports it (start it with the
  user's OK). Preflight may WARN about an old Docker API — pass WARN lines to agents.
- **Never touch the user's dev stack or dev volumes.** Test stacks use their own compose project (`-p <app>-e2e`),
  container names, host ports (15xxx) and volume or tmpfs; never `down -v` a volume you didn't create; check
  `docker ps` afterwards. See [E2E harness](../features/e2e-playwright-harness.md).
- Restoring a production dump (PII) for a rehearsal: throwaway `postgres:16-alpine` container on its own port, deleted
  afterwards.
- `aspnet` runtime images lack Kerberos: add `GSS Encryption Mode=Disable` to Npgsql connection strings (else
  `libgssapi_krb5.so.2` errors; an unhandled startup exception exits 139).
- Compose: `restart: on-failure` for the API, `depends_on: condition: service_healthy`, healthchecks on db and API.
