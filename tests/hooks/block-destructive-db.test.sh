#!/usr/bin/env bash
# Tests for executable_block-destructive-db.sh: PreToolUse(Bash) guard
# that denies destructive database operations unless an explicit test-env
# marker is present in the command itself.
set -uo pipefail

hook="$HOOKS_DIR/executable_block-destructive-db.sh"
[[ -f $hook ]] || { echo "hook not found: $hook"; exit 1; }

# run "<json>" — pipe JSON to hook, capture stdout.
run() { printf '%s' "$1" | bash "$hook"; }

is_block() {
  echo "$1" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}

fail() { echo "FAIL: $1"; exit 1; }

# ────────────────────────────────────────────────────────
# DENY: Rails / Rake / bin/rails
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"rails db:reset"}}')
is_block "$out" || fail "should deny: rails db:reset — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"bundle exec rake db:drop"}}')
is_block "$out" || fail "should deny: bundle exec rake db:drop — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"bin/rails db:schema:load"}}')
is_block "$out" || fail "should deny: bin/rails db:schema:load — got: $out"

# ────────────────────────────────────────────────────────
# DENY: Django
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"python manage.py flush"}}')
is_block "$out" || fail "should deny: python manage.py flush — got: $out"

# ────────────────────────────────────────────────────────
# DENY: Prisma
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"npx prisma migrate reset"}}')
is_block "$out" || fail "should deny: npx prisma migrate reset — got: $out"

# ────────────────────────────────────────────────────────
# DENY: PostgreSQL CLI tools
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"dropdb myapp_development"}}')
is_block "$out" || fail "should deny: dropdb myapp_development — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP DATABASE foo\""}}')
is_block "$out" || fail "should deny: psql -c DROP DATABASE — got: $out"

# ────────────────────────────────────────────────────────
# DENY: MySQL TRUNCATE
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"mysql -e \"TRUNCATE TABLE users\""}}')
is_block "$out" || fail "should deny: mysql -e TRUNCATE TABLE — got: $out"

# ────────────────────────────────────────────────────────
# ALLOW: explicit test-env markers
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RAILS_ENV=test bundle exec rails db:reset"}}')
[[ -z $out ]] || fail "should allow: RAILS_ENV=test rails db:reset — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx prisma migrate reset"}}')
[[ -z $out ]] || fail "should allow: NODE_ENV=test prisma migrate reset — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.settings.test python manage.py flush"}}')
[[ -z $out ]] || fail "should allow: DJANGO_SETTINGS_MODULE=*test manage.py flush — got: $out"

# ────────────────────────────────────────────────────────
# ALLOW: non-destructive commands
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"rails db:migrate"}}')
[[ -z $out ]] || fail "should allow: rails db:migrate — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"cat README.md"}}')
[[ -z $out ]] || fail "should allow: cat README.md — got: $out"

# ────────────────────────────────────────────────────────
# ALLOW: non-Bash tool payload
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Read","tool_input":{"file_path":"db/schema.rb"}}')
[[ -z $out ]] || fail "should allow non-Bash tool — got: $out"

# ────────────────────────────────────────────────────────
# DENY: case-insensitivity — mixed-case commands still blocked
# (current hook uses grep -i, so DB:RESET must still be caught)
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"Rails DB:RESET"}}')
is_block "$out" || fail "should deny: Rails DB:RESET (case-insensitive) — got: $out"

echo "all assertions passed"
