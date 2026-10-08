#!/usr/bin/env bash
# Tests for executable_block-rot-comments.py: PreToolUse(Write|Edit|Bash)
# guard that blocks code comments containing patterns known to rot, in
# written files and in the diff a Bash `git commit` will record.
set -uo pipefail

hook="$HOOKS_DIR/executable_block-rot-comments.py"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

# run "<json>" — pipe JSON to the hook, capture stdout. Hook is expected
# to either exit silently (allow) or emit a deny JSON (block).
run() { printf '%s' "$1" | python3 "$hook"; }
is_block() {
  echo "$1" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}
reason_has() {
  echo "$1" | jq -e --arg s "$2" '.hookSpecificOutput.permissionDecisionReason | contains($s)' >/dev/null
}

fail() { echo "FAIL: $1"; exit 1; }

# === ALLOW: no input, missing fields ===
out=$(run '{"tool_input":{}}')
[[ -z $out ]] || fail "fired with empty tool_input: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"foo.ts"}}')
[[ -z $out ]] || fail "fired with missing content: $out"

# === ALLOW: prose / docs files ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"README.md","content":"# Project\n\nSee issue #123 for context."}}')
[[ -z $out ]] || fail "fired on .md file: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"docs/spec.mdx","content":"used by the auth flow"}}')
[[ -z $out ]] || fail "fired on .mdx file: $out"

# === ALLOW: shebangs ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"script.sh","content":"#!/usr/bin/env bash\necho hi\n"}}')
[[ -z $out ]] || fail "shebang flagged as rot comment: $out"

# === ALLOW: URL fragments and CSS hex colors are not comments ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"const url = \"http://example.com#section42\";\nconst color = \"#ff0099\";\n"}}')
[[ -z $out ]] || fail "URL fragment / hex color mistaken for comment: $out"

# === ALLOW: legitimate code comments without rot patterns ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// Retries are required because the upstream API drops connections silently.\nfunction f() {}\n"}}')
[[ -z $out ]] || fail "blocked legit explanatory comment: $out"

# === BLOCK: issue / PR reference in comment ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// added for #123\nfunction f() {}\n"}}')
is_block "$out" || fail "did not block '#123' issue reference: $out"
reason_has "$out" "rot" || fail "deny reason missing 'rot' keyword: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.py","content":"# fixes PR-456\ndef f(): pass\n"}}')
is_block "$out" || fail "did not block 'PR-456' reference: $out"

# === BLOCK: caller / usage reference ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// used by handleSubmit\nfunction f() {}\n"}}')
is_block "$out" || fail "did not block 'used by' caller reference: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.go","content":"// called from the auth handler\nfunc f() {}\n"}}')
is_block "$out" || fail "did not block 'called from' caller reference: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.rb","content":"# added for the signup flow\ndef f; end\n"}}')
is_block "$out" || fail "did not block 'added for the X flow': $out"

# === BLOCK: temporal phrasing ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// previously returned null, now returns []\nfunction f() {}\n"}}')
is_block "$out" || fail "did not block 'previously ... now': $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// deprecated as of v2.3\nfunction f() {}\n"}}')
is_block "$out" || fail "did not block 'deprecated as of': $out"

# === BLOCK: bare TODO / FIXME without owner or date ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// TODO: fix this\nfunction f() {}\n"}}')
is_block "$out" || fail "did not block bare TODO: $out"

out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.py","content":"# FIXME: broken\ndef f(): pass\n"}}')
is_block "$out" || fail "did not block bare FIXME: $out"

# === ALLOW: TODO with owner ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// TODO(@alice): rewrite this once the v2 API is ready\nfunction f() {}\n"}}')
[[ -z $out ]] || fail "blocked TODO with owner: $out"

# === ALLOW: TODO with date ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// TODO 2026-12-31: revisit after migration\nfunction f() {}\n"}}')
[[ -z $out ]] || fail "blocked TODO with date: $out"

# === BLOCK: inline trailing comment with rot pattern ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"const x = 42; // used by computeTotal\n"}}')
is_block "$out" || fail "did not block inline trailing rot comment: $out"

# === Edit: only NEW comment lines are checked ===
# Old already had a rot comment; new_string keeps it but does not introduce
# anything new. Should ALLOW because we did not author the rot comment.
old='// used by handleSubmit\nfunction f() { return 1; }\n'
new='// used by handleSubmit\nfunction f() { return 2; }\n'
out=$(run "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"a.ts\",\"old_string\":\"$old\",\"new_string\":\"$new\"}}")
[[ -z $out ]] || fail "blocked edit that did not add the rot comment: $out"

# Edit ADDS a new rot comment → BLOCK.
old='function f() { return 1; }\n'
new='// added for #999\nfunction f() { return 1; }\n'
out=$(run "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"a.ts\",\"old_string\":\"$old\",\"new_string\":\"$new\"}}")
is_block "$out" || fail "did not block edit adding rot comment: $out"

# === ALLOW: Edit that REMOVES a rot comment ===
old='// added for #999\nfunction f() {}\n'
new='function f() {}\n'
out=$(run "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"a.ts\",\"old_string\":\"$old\",\"new_string\":\"$new\"}}")
[[ -z $out ]] || fail "blocked edit that removed a rot comment: $out"

# === MultiEdit: all edits clean → ALLOW ===
out=$(run '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.ts","edits":[{"old_string":"function a() { return 1; }\n","new_string":"function a() { return 2; }\n"},{"old_string":"function b() { return 1; }\n","new_string":"function b() { return 2; }\n"}]}}')
[[ -z $out ]] || fail "MultiEdit with clean edits was blocked: $out"

# === MultiEdit: rot marker in a later edit → BLOCK ===
# Rot pattern assembled at runtime so this source line is not flagged.
_rot_marker='TO''DO: fix later'
_me_payload=$(printf '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.ts","edits":[{"old_string":"function a() {}\\n","new_string":"function a() {}\\n"},{"old_string":"function b() {}\\n","new_string":"// %s\\nfunction b() {}\\n"}]}}' "$_rot_marker")
out=$(run "$_me_payload")
is_block "$out" || fail "MultiEdit with rot marker in later edit was not blocked: $out"
reason_has "$out" "rot" || fail "MultiEdit deny reason missing 'rot' keyword: $out"

# === Write: line-comment rot marker (HA-CK style) → BLOCK ===
_hack='HA''CK: workaround for upstream bug'
_hack_payload=$(printf '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// %s\\nfunction f() {}\\n"}}' "$_hack")
out=$(run "$_hack_payload")
is_block "$out" || fail "did not block line-comment rot marker: $out"

# === Write: block-comment rot marker (TE-MP style) → BLOCK ===
_temp='TE''MP: remove after launch'
_temp_payload=$(printf '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"/* %s */\\nfunction f() {}\\n"}}' "$_temp")
out=$(run "$_temp_payload")
is_block "$out" || fail "did not block block-comment rot marker: $out"

# === Japanese: legit why-comment → ALLOW ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.py","content":"# 上流 API が無言で接続を切るため、再試行が必要\ndef f(): pass\n"}}')
[[ -z $out ]] || fail "blocked legit Japanese why-comment: $out"

# === Japanese: each rot label → BLOCK ===
jp_block() { # jp_block <comment> <expected label fragment>
  local payload
  payload=$(jq -cn --arg c "$1" '{tool_name:"Write",tool_input:{file_path:"a.py",content:("# " + $c + "\ndef f(): pass\n")}}')
  out=$(run "$payload")
  is_block "$out" || fail "did not block Japanese comment '$1': $out"
  reason_has "$out" "$2" || fail "Japanese comment '$1' missing label '$2': $out"
}
jp_block '以前は slug で判定していた' 'temporal phrasing'
jp_block '従来は null を返す' 'temporal phrasing'
jp_block '旧仕様との互換のため残す' 'temporal phrasing'
jp_block '今回の変更で追加した' 'temporal phrasing'
jp_block '新たに追加したフィールド' 'temporal phrasing'
jp_block 'slug 判定に変更した' 'temporal phrasing'
jp_block 'リトライを追加した' 'temporal phrasing'
jp_block 'null チェックを修正した' 'temporal phrasing'
jp_block '互換性対応のため残す' 'temporal phrasing'
jp_block 'handleSubmit から呼ばれる' 'caller / usage reference'
jp_block 'auth ハンドラから呼び出される' 'caller / usage reference'
jp_block 'フォームで使われる' 'caller / usage reference'
jp_block 'この値は別モジュールで使われている' 'caller / usage reference'
jp_block '呼び出し元で検証済み' 'caller / usage reference'
jp_block 'validate_owners.py と一致させる' 'keep-in-sync instruction'
jp_block 'CODEOWNERS と同期させること' 'keep-in-sync instruction'
jp_block 'こちらにも追加する' 'keep-in-sync instruction'
jp_block 'ここも合わせて更新する' 'keep-in-sync instruction'
jp_block 'ここと CODEOWNERS の行に 1 つずつ足す' 'keep-in-sync instruction'
jp_block 'この行と validate_owners.py の MIGRATION_OPS_TEAMS に足す' 'keep-in-sync instruction'
jp_block 'team_id は gh api orgs/C-FO/teams/<slug> で取得した実値' 'provenance'

# === Commit gate: git repo fixtures ===
tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

new_repo() { # new_repo <name> — create an initial-commit repo, print its path
  local dir="$tmp_root/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name Test
  git -C "$dir" config commit.gpgsign false
  printf 'def base(): pass\n' >"$dir/base.py"
  git -C "$dir" add base.py
  git -C "$dir" commit -q -m init
  printf '%s' "$dir"
}
bash_payload() { # bash_payload <cwd> <command>
  jq -cn --arg cwd "$1" --arg cmd "$2" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}'
}
rot_jp='# 以前は slug で判定していた'

# Staged rot comment → BLOCK, reason names the file
repo=$(new_repo staged_rot)
printf '%s\ndef f(): pass\n' "$rot_jp" >"$repo/rotten.py"
git -C "$repo" add rotten.py
out=$(run "$(bash_payload "$repo" 'git commit -m x')")
is_block "$out" || fail "commit gate did not block staged rot comment: $out"
reason_has "$out" "rotten.py" || fail "commit gate reason missing file name: $out"
reason_has "$out" "re-stage" || fail "commit gate reason missing re-stage hint: $out"

# Staged clean code → ALLOW
repo=$(new_repo staged_clean)
printf '# 上流 API が無言で接続を切るため、再試行が必要\ndef f(): pass\n' >"$repo/clean.py"
git -C "$repo" add clean.py
out=$(run "$(bash_payload "$repo" 'git commit -m x')")
[[ -z $out ]] || fail "commit gate blocked clean staged code: $out"

# -am picks up an unstaged modification to a tracked file → BLOCK
repo=$(new_repo all_flag)
printf 'def base(): pass\n%s\n' "$rot_jp" >"$repo/base.py"
out=$(run "$(bash_payload "$repo" 'git commit -am x')")
is_block "$out" || fail "commit gate did not block -am unstaged rot comment: $out"
reason_has "$out" "base.py" || fail "-am reason missing file name: $out"
# Same change without -a is not part of the commit → ALLOW
out=$(run "$(bash_payload "$repo" 'git commit -m x')")
[[ -z $out ]] || fail "commit gate scanned unstaged change without -a: $out"

# Staged prose file with temporal wording → ALLOW
repo=$(new_repo staged_md)
printf '以前は slug で判定していた\n' >"$repo/notes.md"
git -C "$repo" add notes.md
out=$(run "$(bash_payload "$repo" 'git commit -m x')")
[[ -z $out ]] || fail "commit gate blocked a .md file: $out"

# Non-commit Bash commands → ALLOW
repo=$(new_repo non_commit)
printf '%s\ndef f(): pass\n' "$rot_jp" >"$repo/rotten.py"
git -C "$repo" add rotten.py
out=$(run "$(bash_payload "$repo" 'git status')")
[[ -z $out ]] || fail "gate fired on git status: $out"
out=$(run "$(bash_payload "$repo" 'git commit-tree HEAD^{tree}')")
[[ -z $out ]] || fail "gate fired on git commit-tree: $out"

# cd <repo> && git commit with payload cwd elsewhere → BLOCK
repo=$(new_repo cd_prefix)
printf '%s\ndef f(): pass\n' "$rot_jp" >"$repo/rotten.py"
git -C "$repo" add rotten.py
out=$(run "$(bash_payload "$tmp_root" "cd $repo && git commit -m x")")
is_block "$out" || fail "commit gate ignored leading cd: $out"

# git -C <repo> commit → BLOCK
out=$(run "$(bash_payload "$tmp_root" "git -C $repo commit -m x")")
is_block "$out" || fail "commit gate ignored git -C: $out"

# Non-repo directory → fail open
mkdir -p "$tmp_root/not_a_repo"
out=$(run "$(bash_payload "$tmp_root/not_a_repo" 'git commit -m x')")
[[ -z $out ]] || fail "commit gate did not fail open outside a repo: $out"

echo "all assertions passed"
