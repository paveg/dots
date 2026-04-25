#!/usr/bin/env bash
# PreToolUse(Write|Edit) hook: inject path-relevant rule files into
# additionalContext as a single dispatcher. Spawns one bash + one jq per
# edit regardless of how many rules match (vs N processes for N hooks).
#
# Add a new rule by appending a case statement and a rule filename — no
# new hook script, no new settings.json entry.
#
# Reads Claude Code hook JSON from stdin; emits JSON on stdout.
set -euo pipefail

rules_dir="$HOME/.claude/rules"

path=$(jq -r '.tool_input.file_path // ""')
[[ -n $path ]] || exit 0

rules=()

# chezmoi: any file under the chezmoi source tree
case "$path" in
  */.local/share/chezmoi/*) rules+=("chezmoi.md") ;;
esac

# React: .tsx / .jsx source files
case "$path" in
  *.tsx|*.jsx) rules+=("react.md") ;;
esac

# Drizzle: schema files, drizzle.config.*, anything under a drizzle/ dir
case "$path" in
  *schema.ts|*schema.tsx) rules+=("drizzle.md") ;;
  drizzle.config.*|*/drizzle.config.*) rules+=("drizzle.md") ;;
  */drizzle/*) rules+=("drizzle.md") ;;
esac

(( ${#rules[@]} > 0 )) || exit 0

body=""
for r in "${rules[@]}"; do
  f="$rules_dir/$r"
  [[ -f $f ]] || continue
  [[ -n $body ]] && body+=$'\n\n---\n\n'
  body+=$(cat "$f")
done

[[ -n $body ]] || exit 0

jq -n --arg body "$body" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $body
  }
}'
