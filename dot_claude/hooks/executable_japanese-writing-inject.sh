#!/usr/bin/env bash
# PreToolUse(Write|Edit) hook: inject a japanese-writing norms pointer as
# additionalContext when a .md file is being written/edited with Japanese
# content. Reads Claude Code hook JSON from stdin; emits JSON on stdout.
# Fails closed to silence on any non-match, missing field, or error.
set -euo pipefail

norms="$HOME/.claude/references/japanese-writing/norms.md"

input=$(cat)

file_path=$(jq -r '.tool_input.file_path // ""' <<<"$input")

case $file_path in
*.md) ;;
*) exit 0 ;;
esac

content=$(jq -r '.tool_input.content // .tool_input.new_string // ""' <<<"$input")

# perl -CSD decodes stdin/stdout as UTF-8 so \p{...} matches actual Hiragana/
# Katakana/Han codepoints. BSD grep (macOS default) has no -P/PCRE support,
# so this cannot be done with grep alone here.
if ! printf '%s' "$content" | perl -CSD -ne 'exit(/\p{Hiragana}|\p{Katakana}|\p{Han}/ ? 0 : 1)'; then
  exit 0
fi

body="Japanese writing norms: $norms
Apply these norms (structure, rhythm, cognitive rhythm, AI-smell) to the Japanese prose.
Before finalizing, run the japanese-ai-writing-proofreader skill in fix mode."

jq -n --arg body "$body" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
