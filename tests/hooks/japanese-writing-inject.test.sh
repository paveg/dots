#!/usr/bin/env bash
# Tests for executable_japanese-writing-inject.sh: PreToolUse(Write|Edit)
# hook that injects a japanese-writing norms pointer when a .md file is
# being written/edited with Japanese content, and stays silent otherwise.
set -uo pipefail

hook="$HOOKS_DIR/executable_japanese-writing-inject.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

run() {
  printf '%s' "$1" | bash "$hook"
}

contains_norms_pointer() {
  echo "$1" | jq -e '.hookSpecificOutput.additionalContext | contains("references/japanese-writing/norms.md")' >/dev/null
}

# Edge: missing tool_input should not crash
out=$(run '{"tool_name":"Write"}')
[[ -z $out ]] || { echo "fired on missing tool_input: $out"; exit 1; }

# Green: Write to .md with Japanese content fires
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"これは日本語の文章です"}}')
contains_norms_pointer "$out" || { echo "pointer not injected for japanese .md write: $out"; exit 1; }

# Regression: the pointer must NOT summon the proofreader skill — hook-driven
# proofreading burns a full pipeline run on every Japanese .md write
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("writing-proofread")' >/dev/null \
  && { echo "proofreader skill mention resurfaced: $out"; exit 1; }

# Edge: .py file with Japanese content must NOT fire
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"script.py","content":"# 日本語コメント"}}')
[[ -z $out ]] || { echo "fired on .py file: $out"; exit 1; }

# Edge: .md file with English-only content must NOT fire
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"plain english content"}}')
[[ -z $out ]] || { echo "fired on english-only .md: $out"; exit 1; }

# Green: Edit uses tool_input.new_string
out=$(run '{"tool_name":"Edit","tool_input":{"file_path":"doc.md","old_string":"old","new_string":"日本語の変更を加えた文章"}}')
contains_norms_pointer "$out" || { echo "pointer not injected for japanese .md edit: $out"; exit 1; }

# Edge: Edit to .md with English-only new_string must NOT fire
out=$(run '{"tool_name":"Edit","tool_input":{"file_path":"doc.md","old_string":"old","new_string":"english only"}}')
[[ -z $out ]] || { echo "fired on english-only .md edit: $out"; exit 1; }

# Edge: nested .md path still matches (suffix check, not basename-only)
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"docs/adr/0001-foo.md","content":"これは日本語の文章です"}}')
contains_norms_pointer "$out" || { echo "pointer not injected for nested .md path: $out"; exit 1; }

# Edge: file that merely contains .md mid-path but does not end with .md must NOT fire
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md.bak","content":"これは日本語の文章です"}}')
[[ -z $out ]] || { echo "fired on non-.md suffix path: $out"; exit 1; }

# Edge: Japanese content on a non-first line must still fire (multi-line scan,
# not just the first line)
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"# English Title\n\n本文は日本語"}}')
contains_norms_pointer "$out" || { echo "pointer not injected for japanese on non-first line: $out"; exit 1; }

# Regression: English prose that only mentions Japanese punctuation examples
# (e.g. rules docs listing 。．！？ as sentence-boundary examples) must NOT
# fire. \p{Han} matches CJK punctuation via script-extensions, so a naive
# CJK-codepoint test over-triggers on this.
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"Break after a sentence boundary (。．！？) — never mid-clause."}}')
[[ -z $out ]] || { echo "fired on english prose with only japanese punctuation examples: $out"; exit 1; }

# Edge: a couple of Japanese example words below the 15% density threshold
# must NOT fire.
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"Use the 校正 skill; otherwise write normal English prose that dominates the whole paragraph by a wide margin so Japanese stays a small fraction."}}')
[[ -z $out ]] || { echo "fired on low-density japanese example: $out"; exit 1; }

# Green: genuine Japanese prose at or above the 15% density threshold fires.
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"この設計は状況を更新する文を優先する。読者の理解を前に進める文だけを残す。"}}')
contains_norms_pointer "$out" || { echo "pointer not injected for genuine japanese prose: $out"; exit 1; }

echo "all assertions passed"
