#!/usr/bin/env bash
# Tests for executable_block-destructive-db.sh: PreToolUse(Bash) guard
# that denies known destructive database operations regardless of
# test-environment markers.
set -euo pipefail

hook="$HOOKS_DIR/executable_block-destructive-db.sh"
[[ -f $hook ]] || {
  echo "hook not found: $hook"
  exit 1
}

# run "<json>" — pipe JSON to the hook, capture stdout.
run() { printf '%s' "$1" | bash "$hook"; }

run_command() {
  local payload
  payload=$(jq -nc --arg command "$1" '{tool_name:"Bash",tool_input:{command:$command}}')
  run "$payload"
}

is_block() {
  echo "$1" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}

fail() {
  echo "FAIL: $1"
  exit 1
}

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
# DENY: test-env markers are not datasource proof
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RAILS_ENV=test bundle exec rails db:reset"}}')
is_block "$out" || fail "should deny despite RAILS_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop"}}')
is_block "$out" || fail "should deny despite NODE_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"CI=1 NODE_ENV=test npx sequelize db:drop"}}')
is_block "$out" || fail "should deny despite preceding env assignment — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"env NODE_ENV=test npx sequelize db:drop"}}')
is_block "$out" || fail "should deny env-prefixed NODE_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=production NODE_ENV=test npx sequelize db:drop"}}')
is_block "$out" || fail "should deny despite final NODE_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=\"test\" npx sequelize db:drop"}}')
is_block "$out" || fail "should deny quoted literal test value — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx knex migrate:rollback --all"}}')
is_block "$out" || fail "should deny despite NODE_ENV=test knex rollback — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RACK_ENV=test bundle exec rake db:drop"}}')
is_block "$out" || fail "should deny despite RACK_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.settings.test python manage.py flush"}}')
is_block "$out" || fail "should deny despite test Django settings — got: $out"

# Test markers never bypass any supported runner shape.
marked_destructive_commands=(
  'RAILS_ENV=test ./bin/rails db:drop'
  'NODE_ENV=test sequelize db:drop'
  'NODE_ENV=test ./node_modules/.bin/knex migrate:rollback --all'
  'NODE_ENV=test bunx sequelize db:drop'
  'NODE_ENV=test pnpm exec sequelize db:drop'
  'NODE_ENV=test yarn knex migrate:rollback --all'
  'NODE_ENV=test npm exec -- sequelize db:drop'
  'DJANGO_SETTINGS_MODULE=app.settings.test ./manage.py flush'
  'DJANGO_SETTINGS_MODULE=app.settings.test uv run python manage.py flush'
  'DJANGO_SETTINGS_MODULE=app.settings.test poetry run python manage.py flush'
  'DJANGO_SETTINGS_MODULE=app.settings.test pipenv run python manage.py flush'
)

for command in "${marked_destructive_commands[@]}"; do
  out=$(run_command "$command")
  is_block "$out" || fail "should deny marked destructive command: $command — got: $out"
done

# ────────────────────────────────────────────────────────
# DENY: unrelated or incorrectly scoped test-env markers
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npm test && rails db:reset"}}')
is_block "$out" || fail "should deny marker on an earlier command — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"echo NODE_ENV=test; npx prisma migrate reset"}}')
is_block "$out" || fail "should deny marker used as an argument — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test rails db:reset"}}')
is_block "$out" || fail "should deny Node marker for Rails — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RAILS_ENV=test npx prisma migrate reset"}}')
is_block "$out" || fail "should deny Rails marker for Prisma — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop && rails db:drop"}}')
is_block "$out" || fail "should inspect every destructive command — got: $out"

# shellcheck disable=SC2016 # command substitution must remain literal test input
out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test echo \"$(npx sequelize db:drop)\""}}')
is_block "$out" || fail "should deny destructive command substitution — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test cat <(npx sequelize db:drop)"}}')
is_block "$out" || fail "should deny input process substitution — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test tee >(npx sequelize db:drop)"}}')
is_block "$out" || fail "should deny output process substitution — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.settings.latest python manage.py flush"}}')
is_block "$out" || fail "should deny non-test Django settings module — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.settings.production_test python manage.py flush"}}')
is_block "$out" || fail "should deny Django test substring — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.test.production python manage.py flush"}}')
is_block "$out" || fail "should deny non-final Django test component — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"node_env=test npx sequelize db:drop"}}')
is_block "$out" || fail "should deny lowercase node_env — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=TEST npx sequelize db:drop"}}')
is_block "$out" || fail "should deny uppercase TEST value — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test NODE_ENV=development npx sequelize db:drop"}}')
is_block "$out" || fail "should deny later NODE_ENV override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test env -u NODE_ENV npx sequelize db:drop"}}')
is_block "$out" || fail "should deny later env removal — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test sh -c \"NODE_ENV=production npx sequelize db:drop\""}}')
is_block "$out" || fail "should deny nested shell override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test /bin/\"sh\" -c \"NODE_ENV=production npx sequelize db:drop\""}}')
is_block "$out" || fail "should deny quote-concatenated nested shell — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test dash -c \"NODE_ENV=production npx sequelize db:drop\""}}')
is_block "$out" || fail "should deny unlisted nested shell — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test e\"nv\" -u NODE_ENV npx sequelize db:drop"}}')
is_block "$out" || fail "should deny quote-concatenated env removal — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test DATABASE_URL=postgresql://localhost/app_development npx sequelize db:drop"}}')
is_block "$out" || fail "should deny explicit database connection override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop --env production"}}')
is_block "$out" || fail "should deny Sequelize environment override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop --url postgresql://localhost/app_production"}}')
is_block "$out" || fail "should deny Sequelize connection override — got: $out"

# shellcheck disable=SC2016 # variable expansion must remain literal test input
out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop $EXTRA_ARGS"}}')
is_block "$out" || fail "should deny dynamic argument expansion — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop {--env,production}"}}')
is_block "$out" || fail "should deny brace-expanded override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize db:drop *"}}')
is_block "$out" || fail "should deny glob-expanded arguments — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx knex migrate:rollback --all --env production"}}')
is_block "$out" || fail "should deny Knex environment override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"DJANGO_SETTINGS_MODULE=app.settings.test python manage.py flush --settings=app.settings.production"}}')
is_block "$out" || fail "should deny Django settings override — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx sequelize --env production db:drop"}}')
is_block "$out" || fail "should deny Sequelize override before operation — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx knex --knexfile ./production.js migrate:rollback --all"}}')
is_block "$out" || fail "should deny Knex override before operation — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RAILS_ENV=test bundle exec rails --environment production db:drop"}}')
is_block "$out" || fail "should deny Rails override before operation — got: $out"

# Quoted or escaped separators inside option values stay in one shell command.
out=$(run_command "NODE_ENV=test npx sequelize --config 'config;test.js' db:drop")
is_block "$out" || fail "should deny Sequelize after quoted semicolon — got: $out"

out=$(run_command 'NODE_ENV=test npx sequelize --config=config\;test.js db:drop')
is_block "$out" || fail "should deny Sequelize after escaped semicolon — got: $out"

out=$(run_command "NODE_ENV=test npx knex --knexfile 'knex|test.js' migrate:rollback --all")
is_block "$out" || fail "should deny Knex after quoted pipe — got: $out"

out=$(run_command "npx typeorm --dataSource 'foo;bar.ts' schema:drop")
is_block "$out" || fail "should deny TypeORM after quoted semicolon — got: $out"

# The deny-only scan intentionally crosses real control operators too. Split
# diagnostics into separate Bash calls if they only print these strings.
out=$(run_command "sequelize --help; echo 'db:drop'")
is_block "$out" || fail "should conservatively deny cross-command task text — got: $out"

# A backslash-newline is conservatively denied. Blindly removing it would
# incorrectly join even-backslash newlines, which are real shell separators.
out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test \\\nnpx sequelize db:drop"}}')
is_block "$out" || fail "should deny ambiguous line continuation — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test echo \\\\\nnpx sequelize db:drop"}}')
is_block "$out" || fail "should deny even-backslash newline separator — got: $out"

# Deny detection canonicalizes shell token construction before matching.
out=$(run_command 'NODE_ENV=production npx se"quelize" db:drop')
is_block "$out" || fail "should deny quote-constructed runner — got: $out"

out=$(run_command 'NODE_ENV=production npx sequelize db:"drop"')
is_block "$out" || fail "should deny quote-constructed operation — got: $out"

out=$(run_command 'NODE_ENV=production npx seque\lize db:drop')
is_block "$out" || fail "should deny backslash-constructed runner — got: $out"

out=$(run_command 'dr"opdb" app_production')
is_block "$out" || fail "should deny quote-constructed raw client — got: $out"

# NODE_ENV does not select the Prisma or TypeORM datasource.
out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx prisma migrate reset"}}')
is_block "$out" || fail "should deny Prisma despite NODE_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test npx typeorm schema:drop"}}')
is_block "$out" || fail "should deny TypeORM despite NODE_ENV=test — got: $out"

# Raw clients select their target independently of application env markers.
out=$(run '{"tool_name":"Bash","tool_input":{"command":"NODE_ENV=test psql -c \"DROP DATABASE foo\""}}')
is_block "$out" || fail "should deny raw SQL despite NODE_ENV=test — got: $out"

out=$(run '{"tool_name":"Bash","tool_input":{"command":"RAILS_ENV=test dropdb myapp_test"}}')
is_block "$out" || fail "should deny dropdb despite RAILS_ENV=test — got: $out"

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
# (the detection copy is lowercased before pattern matching)
# ────────────────────────────────────────────────────────

out=$(run '{"tool_name":"Bash","tool_input":{"command":"Rails DB:RESET"}}')
is_block "$out" || fail "should deny: Rails DB:RESET (case-insensitive) — got: $out"

echo "all assertions passed"
