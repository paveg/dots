#!/usr/bin/env bash
# PreToolUse(Bash) hook: inject ~/.claude/rules/gh-pr-body.md as
# additionalContext when the command contains `gh pr create` or `gh pr edit`.
# Also appends a japanese-writing norms pointer when the command's PR body
# contains Japanese text. Reads Claude Code hook JSON from stdin; emits JSON
# on stdout.
set -euo pipefail

rule="$HOME/.claude/rules/gh-pr-body.md"
norms="$HOME/.claude/references/japanese-writing/norms.md"

cmd=$(jq -r '.tool_input.command // ""')

if ! printf '%s' "$cmd" | grep -qE '\bgh pr (create|edit)\b'; then
  exit 0
fi

[[ -f $rule ]] || exit 0

body=$(cat "$rule")

# perl -CSD decodes stdin/stdout as UTF-8 so \p{...} matches actual Hiragana/
# Katakana/Han codepoints. -0777 slurps the whole command into one string so
# multi-line bodies are scanned, not just the first line. BSD grep (macOS
# default) has no -P/PCRE support, so this cannot be done with grep alone.
if printf '%s' "$cmd" | perl -CSD -0777 -ne 'exit(/\p{Hiragana}|\p{Katakana}|\p{Han}/ ? 0 : 1)'; then
  body="$body

Japanese writing norms: $norms
Apply these norms (structure, rhythm, cognitive rhythm, AI-smell) to the Japanese prose.
Before finalizing, run the japanese-ai-writing-proofreader skill in fix mode."
fi

jq -n --arg body "$body" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
