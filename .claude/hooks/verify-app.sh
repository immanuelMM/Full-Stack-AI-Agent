#!/usr/bin/env bash
# Quality gate run when a subagent or team task finishes: builds and lints/type-checks every app folder
# that has uncommitted code changes. Exit 2 sends the failures back to the agent so it keeps working.
# Tests are not run here (they can need Docker/PostgreSQL); qa-automation runs them.

input=$(cat)
# Already blocked once in this stop cycle — let it stop to avoid a loop.
echo "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

root="$(cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}/.." && pwd)"
. "$root/full-stack-agent/.claude/hooks/handback-guard.sh"
report=""
failed=""

check() { # <label> <dir> <command>
  local out
  out=$(cd "$2" && eval "$3" 2>&1) || {
    report+=$'\n'"### $1 failed: $3"$'\n'"$(echo "$out" | tail -n 40)"$'\n'
    failed+="$1;"
  }
}

for app in "$root"/*/; do
  app=${app%/}
  [ "$(basename "$app")" = "full-stack-agent" ] && continue
  changed=$(git -C "$app" status --porcelain 2>/dev/null) || continue

  if [ -d "$app/backend" ] && echo "$changed" | grep -qE '^.. "?backend/'; then
    if compgen -G "$app/backend/*.sln*" >/dev/null || compgen -G "$app/backend/*.csproj" >/dev/null; then
      check "$(basename "$app")/backend" "$app/backend" "dotnet build -nologo -v q"
    else
      # No solution at the backend root (e.g. an app before its restructure): build each project below it.
      while IFS= read -r proj; do
        check "$(basename "$app")/backend/${proj#"$app/backend/"}" "$app/backend" "dotnet build \"$proj\" -nologo -v q"
      done < <(find "$app/backend" -maxdepth 4 -name '*.csproj' -not -path '*/bin/*' -not -path '*/obj/*' | sort)
    fi
  fi
  if [ -f "$app/frontend/package.json" ] && echo "$changed" | grep -qE '^.. "?frontend/'; then
    check "$(basename "$app")/frontend" "$app/frontend" "npm run lint --if-present && npm run build --if-present"
  fi
  if [ -f "$app/site/package.json" ] && echo "$changed" | grep -qE '^.. "?site/'; then
    check "$(basename "$app")/site" "$app/site" "npm run build --if-present"
  fi
done

if [ -n "$report" ]; then
  # Once per session per set of failing checks: a failure in another agent's in-progress work, or a teammate whose
  # spawning agent has exited, must not keep this agent from finishing (TaskCompleted has no stop_hook_active).
  handback "Quality gate failed — fix these before finishing (if a failure is in files another agent owns, say so in
your report and finish):$report" "verify:$failed"
fi
exit 0
