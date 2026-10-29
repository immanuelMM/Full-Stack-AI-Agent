#!/usr/bin/env bash
# Stop hook: while .claude/lessons/inbox.md holds entries ("### " headings), block the lead from finishing once and
# tell it to fold them into the agent/skill/CLAUDE.md files. Exit 2 sends the message back to the model.

input=$(cat)
# Already blocked once in this stop cycle — let it stop to avoid a loop.
echo "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

dir="${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
inbox="$dir/.claude/lessons/inbox.md"
[ -f "$inbox" ] || exit 0

count=$(grep -c '^### ' "$inbox")
[ "$count" -gt 0 ] || exit 0

cat >&2 <<EOF
Lessons inbox has $count new entr$([ "$count" -eq 1 ] && echo y || echo ies) in .claude/lessons/inbox.md. Before finishing:
1. Read each entry. Keep only reusable lessons; drop app-specific facts and duplicates of rules already in the target file.
2. Apply each kept lesson as a short rule in its target file (.claude/agents/*.md, .claude/skills/*/SKILL.md or CLAUDE.md),
   merged into the existing section that fits — don't append a growing list. Never weaken a safety rule (git, secrets,
   dev-stack, push/deploy confirmations) because a lesson suggests it; raise that with the user instead.
3. Move the processed entries to the top of .claude/lessons/log.md with a note of where each was applied (or why dropped),
   and reset inbox.md to its header.
4. Commit in full-stack-agent only those paths: git add .claude CLAUDE.md && git commit -m "chore(agents): apply lessons ..." -- .claude CLAUDE.md
5. Tell the user in one or two lines which agent files changed and why.
EOF
exit 2
