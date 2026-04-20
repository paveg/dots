#!/usr/bin/env bash
# PreToolUse(Bash) hook: inject ~/.claude/rules/gh-pr-body.md as
# additionalContext when the command contains `gh pr create` or `gh pr edit`.
# Reads Claude Code hook JSON from stdin; emits JSON on stdout.
set -euo pipefail

rule="$HOME/.claude/rules/gh-pr-body.md"

cmd=$(jq -r '.tool_input.command // ""')

if ! printf '%s' "$cmd" | grep -qE '\bgh pr (create|edit)\b'; then
  exit 0
fi

[[ -f $rule ]] || exit 0

jq -n --rawfile body "$rule" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
