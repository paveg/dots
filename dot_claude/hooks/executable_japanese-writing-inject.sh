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

# perl -CSD decodes stdin/stdout as UTF-8 so codepoint ranges match actual
# Hiragana/Katakana/Han characters. -0777 slurps the whole content into one
# string so multi-line docs are scanned, not just the first line. BSD grep
# (macOS default) has no -P/PCRE support, so this cannot be done with grep
# alone. Density (kana/kanji share of non-space characters), not mere
# presence, gates the fire: \p{Han} matches CJK punctuation like 。 via
# script-extensions, so a naive presence check fires on English prose that
# only mentions Japanese punctuation as an example. Fire only when there are
# at least 10 non-space characters and kana/kanji make up >= 15% of them.
if ! printf '%s' "$content" | perl -CSD -0777 -ne '
  my $jp  = () = /[\x{3041}-\x{3096}\x{30A1}-\x{30FA}\x{30FC}\x{4E00}-\x{9FFF}]/g;
  my $tot = () = /\S/g;
  exit( ($tot >= 10 && $jp / $tot >= 0.15) ? 0 : 1 );
'; then
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
