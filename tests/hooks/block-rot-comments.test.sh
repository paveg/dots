#!/usr/bin/env bash
# Tests for executable_block-rot-comments.py: PreToolUse(Write|Edit) guard
# that blocks code comments containing patterns known to rot — references
# to current task/PR/issue numbers, caller names, temporal phrasing
# ("previously", "now does"), and TODO/FIXME without owner or date.
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

echo "all assertions passed"
