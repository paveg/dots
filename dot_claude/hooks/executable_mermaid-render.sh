#!/usr/bin/env bash
# Stop hook: render mermaid code blocks from the last assistant message as
# ASCII art via mermaid-ascii. Only supported diagram types (graph/flowchart/
# sequenceDiagram) are rendered; unsupported types are silently skipped so
# the assistant response is never disrupted.
#
# Input: Claude Code hook JSON on stdin (uses .transcript_path).
# Output: ASCII-rendered diagrams to stdout, shown after the response.
set -euo pipefail

# Skip interactive invocation (no piped stdin).
[[ -t 0 ]] && exit 0

# Locate mermaid-ascii. Hook PATH may not include $GOPATH/bin.
if command -v mermaid-ascii >/dev/null 2>&1; then
  mmd_bin="mermaid-ascii"
elif [[ -x "$HOME/go/bin/mermaid-ascii" ]]; then
  mmd_bin="$HOME/go/bin/mermaid-ascii"
else
  exit 0
fi

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)
[[ -n $transcript && -f $transcript ]] || exit 0

# Extract the last assistant message's concatenated text content.
last_text=$(jq -rs '
  [.[] | select(.type == "assistant" and (.message.content | type) == "array")]
  | last
  | (.message.content // [])
  | map(select(.type == "text") | .text)
  | join("\n")
' "$transcript" 2>/dev/null || true)

[[ -n $last_text ]] || exit 0

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Split mermaid fenced blocks into individual files.
printf '%s\n' "$last_text" | awk -v d="$tmpdir" '
  /^```mermaid[[:space:]]*$/ { n++; in_block=1; path=d "/block-" n ".mmd"; next }
  /^```[[:space:]]*$/ && in_block { in_block=0; close(path); next }
  in_block { print > path }
'

shopt -s nullglob
blocks=("$tmpdir"/block-*.mmd)
(( ${#blocks[@]} > 0 )) || exit 0

# Allowlist: mermaid-ascii supports only these diagram headers.
supported=()
for b in "${blocks[@]}"; do
  first=$(awk 'NF { print; exit }' "$b")
  case "$first" in
    graph\ *|flowchart\ *|sequenceDiagram*) supported+=("$b") ;;
  esac
done

(( ${#supported[@]} > 0 )) || exit 0

total=${#supported[@]}
for ((i=0; i<total; i++)); do
  printf '\n─── mermaid (%d/%d) ───\n' "$((i+1))" "$total"
  "$mmd_bin" -f "${supported[$i]}" 2>/dev/null || printf '(render failed)\n'
done
