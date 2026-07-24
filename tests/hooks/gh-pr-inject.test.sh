#!/usr/bin/env bash
# Tests for executable_gh-pr-inject.sh: PreToolUse(Bash) hook that injects
# ~/.claude/rules/gh-pr-body.md for any `gh pr create|edit`, plus a
# japanese-writing norms pointer when the command's PR body contains
# Japanese text.
set -uo pipefail

hook="$HOOKS_DIR/executable_gh-pr-inject.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

run() {
  printf '%s' "$1" | bash "$hook"
}

contains_norms_pointer() {
  echo "$1" | jq -e '.hookSpecificOutput.additionalContext | contains("references/japanese-writing/norms.md")' >/dev/null
}

# Edge: non gh-pr command should produce no output
out=$(run '{"tool_input":{"command":"ls"}}')
[[ -z $out ]] || { echo "fired on unrelated command: $out"; exit 1; }

# Green: English-only PR body still gets the base rule injection
out=$(run '{"tool_input":{"command":"gh pr create --title foo --body \"plain english body\""}}')
[[ -n $out ]] || { echo "base rule not injected for english body: $out"; exit 1; }
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("backslash")' >/dev/null \
  || { echo "gh-pr-body.md rule missing from english output: $out"; exit 1; }

# Green: English-only PR body must NOT get the Japanese norms pointer
contains_norms_pointer "$out" && { echo "japanese pointer fired on english-only body: $out"; exit 1; }

# Green: Japanese PR body gets the norms pointer IN ADDITION to the base rule
out=$(run '{"tool_input":{"command":"gh pr create --title foo --body \"日本語の本文です\""}}')
contains_norms_pointer "$out" || { echo "japanese pointer not injected for japanese body: $out"; exit 1; }
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("backslash")' >/dev/null \
  || { echo "gh-pr-body.md rule missing from japanese output: $out"; exit 1; }

# Green: gh pr edit with Japanese body also fires
out=$(run '{"tool_input":{"command":"gh pr edit 123 --body \"変更内容の説明\""}}')
contains_norms_pointer "$out" || { echo "japanese pointer not injected for gh pr edit: $out"; exit 1; }

# Regression: the pointer must NOT summon the proofreader skill — hook-driven
# proofreading burns a full pipeline run on every Japanese PR body
out=$(run '{"tool_input":{"command":"gh pr create --body \"日本語の本文です\""}}')
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("japanese-ai-writing-proofreader")' >/dev/null \
  && { echo "proofreader skill mention resurfaced: $out"; exit 1; }

# Edge: Japanese content on a non-first line of a multi-line --body must
# still fire (multi-line scan, not just the first line)
out=$(run '{"tool_input":{"command":"gh pr create --body \"english intro\n日本語の本文\""}}')
contains_norms_pointer "$out" || { echo "pointer not injected for japanese on non-first line: $out"; exit 1; }

# Regression: an English body that only mentions Japanese punctuation as an
# example must NOT get the Japanese norms pointer (the base gh-pr-body.md
# rule injection may still fire).
out=$(run '{"tool_input":{"command":"gh pr create --body \"English body that only mentions 。 as an example.\""}}')
contains_norms_pointer "$out" && { echo "japanese pointer fired on punctuation-only mention: $out"; exit 1; }

echo "all assertions passed"
