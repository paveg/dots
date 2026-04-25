#!/usr/bin/env bash
# PreToolUse hook: inject ~/.claude/rules/browser-automation.md as
# additionalContext when invoking any mcp__claude-in-chrome__* tool.
# Reads Claude Code hook JSON from stdin; emits JSON on stdout.
set -euo pipefail

rule="$HOME/.claude/rules/browser-automation.md"

tool=$(jq -r '.tool_name // ""')

case "$tool" in
  mcp__claude-in-chrome__*) ;;
  *) exit 0 ;;
esac

[[ -f $rule ]] || exit 0

jq -n --rawfile body "$rule" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
