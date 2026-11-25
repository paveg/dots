#!/usr/bin/env bash
# Tests for executable_check-reply-language.sh: when the user's last message is
# Japanese and the reply is mostly English, block once so Claude rewrites it.
set -uo pipefail

hook="$HOOKS_DIR/executable_check-reply-language.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

transcript() { # <user text> -> path of a one-message transcript
  local path=$work/t-$RANDOM.jsonl
  jq -nc --arg t "$1" '{type: "user", message: {role: "user", content: $t}}' >"$path"
  echo "$path"
}

run() { # <transcript> <last reply> [stop_hook_active]
  jq -nc --arg p "$1" --arg r "$2" --argjson a "${3:-false}" \
    '{transcript_path: $p, last_assistant_message: $r, stop_hook_active: $a}' | bash "$hook"
}

blocks() { jq -e '.decision == "block" and (.reason | length > 0)' >/dev/null 2>&1 <<<"$1"; }

ja=$(transcript 'このPRをマージしてよいですか、確認してください')
en=$(transcript 'Please merge the pull request now')
english='I merged the pull request and the checks on main passed. Nothing else needs your decision right now, and the next issue can start whenever you are ready to review it.'
japanese='PR をマージしました。main の CI も通っています。いまあなたの判断を待っているものはありません。'

# Red: Japanese message, English reply
out=$(run "$ja" "$english")
blocks "$out" || { echo "did not block an English reply to Japanese: $out"; exit 1; }

# Green: Japanese reply, English reply to an English message
out=$(run "$ja" "$japanese")
[[ -z $out ]] || { echo "blocked a Japanese reply: $out"; exit 1; }
out=$(run "$en" "$english")
[[ -z $out ]] || { echo "blocked an English reply to English: $out"; exit 1; }

# Green: a Japanese reply that pastes a long English log is still Japanese
log=$(for i in $(seq 1 30); do echo "ok: check number $i passed on the macos runner"; done)
out=$(run "$ja" "テストの結果です。
\`\`\`
$log
\`\`\`
すべて通りました。")
[[ -z $out ]] || { echo "counted a code block as English: $out"; exit 1; }

# Edge: a second stop never blocks again, and broken input fails open
out=$(run "$ja" "$english" true)
[[ -z $out ]] || { echo "blocked a second time: $out"; exit 1; }
out=$(printf 'not json' | bash "$hook" 2>/dev/null)
[[ -z $out ]] || { echo "did not fail open on bad input: $out"; exit 1; }

exit 0
