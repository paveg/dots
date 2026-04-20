#!/usr/bin/env bash
# PreToolUse(Write|Edit) hook: inject ~/.claude/rules/chezmoi.md as
# additionalContext when file_path is under ~/.local/share/chezmoi/.
# Reads Claude Code hook JSON from stdin; emits JSON on stdout.
set -euo pipefail

rule="$HOME/.claude/rules/chezmoi.md"

path=$(jq -r '.tool_input.file_path // ""')

case "$path" in
  */.local/share/chezmoi/*) ;;
  *) exit 0 ;;
esac

[[ -f $rule ]] || exit 0

jq -n --rawfile body "$rule" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
