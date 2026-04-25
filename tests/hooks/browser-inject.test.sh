#!/usr/bin/env bash
# Tests for executable_browser-inject.sh: should inject browser-automation.md
# when invoking any mcp__claude-in-chrome__* tool, and stay silent otherwise.
set -uo pipefail

hook="$HOOKS_DIR/executable_browser-inject.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

run() {
  printf '%s' "$1" | bash "$hook"
}

contains_rule() {
  echo "$1" | jq -e '.hookSpecificOutput.additionalContext | contains("Browser Automation")' >/dev/null
}

# Red: non-chrome tool should produce no output
out=$(run '{"tool_name":"Bash","tool_input":{"command":"ls"}}')
[[ -z $out ]] || { echo "fired on Bash: $out"; exit 1; }

# Green: chrome MCP tool should inject the rule
out=$(run '{"tool_name":"mcp__claude-in-chrome__navigate","tool_input":{"url":"https://example.com"}}')
contains_rule "$out" || { echo "rule not injected for navigate: $out"; exit 1; }

# Green: tabs_context_mcp should also fire
out=$(run '{"tool_name":"mcp__claude-in-chrome__tabs_context_mcp","tool_input":{}}')
contains_rule "$out" || { echo "rule not injected for tabs_context_mcp: $out"; exit 1; }

# Edge: missing tool_name should not crash
out=$(run '{"tool_input":{}}')
[[ -z $out ]] || { echo "fired on missing tool_name: $out"; exit 1; }

# Edge: similarly-named non-chrome tool should not match
out=$(run '{"tool_name":"mcp__some-other-server__tool","tool_input":{}}')
[[ -z $out ]] || { echo "fired on non-chrome MCP tool: $out"; exit 1; }
