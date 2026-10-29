#!/usr/bin/env bash
# Environment preflight before starting or building an app. Run by the lead (not a hook):
#   bash .claude/hooks/preflight.sh fullstack   # or: static
# Prints OK / WARN / FAIL per tool and exits 1 if anything blocks the build.

kind=${1:-fullstack}
fail=0
ok()   { printf '  OK    %s\n' "$*"; }
warn() { printf '  WARN  %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; fail=1; }

echo "Preflight ($kind)"

command -v git >/dev/null && ok "git $(git --version | awk '{print $3}')" || bad "git not found"

# Node 22+ (all apps build a frontend or static site)
if command -v node >/dev/null; then
  nv=$(node -v | sed 's/^v//'); major=${nv%%.*}
  [ "$major" -ge 22 ] && ok "node $nv" || warn "node $nv — Node 22 LTS or newer recommended (CI and Docker images use 22)"
else
  bad "node not found — install Node 22 LTS"
fi
if command -v npm >/dev/null; then
  ok "npm $(npm -v)"
  # npm 10.8.x on this machine fails `npm install` with "Cannot read properties of null (reading 'edgesOut')".
  case "$(npm -v)" in 10.8.*) warn "npm $(npm -v): if 'npm install' fails with an 'edgesOut' error, use --legacy-peer-deps (npm ci still works)";; esac
fi

if [ "$kind" = "fullstack" ]; then
  # .NET 10 SDK
  dotnet=$(command -v dotnet || echo "/c/Program Files/dotnet/dotnet.exe")
  if [ -x "$dotnet" ] || command -v dotnet >/dev/null; then
    sdks=$("$dotnet" --list-sdks 2>/dev/null)
    echo "$sdks" | grep -q '^10\.' && ok ".NET SDK $(echo "$sdks" | grep '^10\.' | tail -1 | awk '{print $1}')" \
      || bad ".NET 10 SDK missing (have: $(echo "$sdks" | awk '{print $1}' | tr '\n' ' ')) — winget install Microsoft.DotNet.SDK.10"
  else
    bad "dotnet not found — winget install Microsoft.DotNet.SDK.10"
  fi

  # Docker daemon (PostgreSQL via compose, Testcontainers, E2E)
  if command -v docker >/dev/null; then
    if api=$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null) && [ -n "$api" ]; then
      ok "docker engine $(docker version --format '{{.Server.Version}}') (API $api)"
      # Testcontainers 4.x defaults to API 1.44; older engines need DOCKER_API_VERSION pinned.
      if [ "$(printf '%s\n1.44\n' "$api" | sort -V | head -1)" != "1.44" ]; then
        warn "Docker API $api < 1.44 — Testcontainers needs DOCKER_API_VERSION=$api locally (update Docker Desktop to drop this)"
      fi
    else
      bad "docker daemon not running — start Docker Desktop"
    fi
  else
    bad "docker not found — install Docker Desktop"
  fi
fi

[ $fail -eq 0 ] && echo "Preflight passed." || echo "Preflight failed — fix the FAIL lines before building."
exit $fail
