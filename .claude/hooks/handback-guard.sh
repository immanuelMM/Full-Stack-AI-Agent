#!/usr/bin/env bash
# Shared loop breaker for hooks that hand work back to an agent (exit 2).
# Source it after reading the hook input into $input, then call `handback <message>` instead of `exit 2`.
#
# A session receives the same hand-back message at most once. If the problem is still there the next time the
# session tries to stop (or complete a task), the hook lets it finish: the lead verifies every report anyway.
# This covers events without `stop_hook_active` (TaskCompleted) and teammates whose spawning agent has exited,
# where an unconditional exit 2 would loop forever.

hook_field() { # <name> -> string value of a top-level JSON field in $input (empty if absent)
  printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

hook_session=$(hook_field session_id)
hook_event=$(hook_field hook_event_name)
hook_agent_id=$(hook_field agent_id)

handback() { # <message> [dedup key, default: the message]: block once per session and key, otherwise allow
  local msg="$1" state_dir key
  state_dir="${TMPDIR:-${TEMP:-/tmp}}/claude-handback/${hook_session:-unknown}"
  key=$(printf '%s' "${2:-$msg}" | cksum | cut -d' ' -f1)
  if [ -f "$state_dir/$key" ]; then
    exit 0
  fi
  mkdir -p "$state_dir" && : > "$state_dir/$key"
  printf '%s\n' "$msg" >&2
  exit 2
}
