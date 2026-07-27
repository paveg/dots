#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny destructive database operations by default.
#
# Why: a tool-invoked `db:reset` (or equivalent across stacks) wipes data
# unconditionally. The same command targets development by default in most
# ORMs, so a wrong run during automated work destroys the developer's local
# DB. Recovery is hours; pausing is zero.
#
# Behavior:
#   - Deny if the command matches a destructive DB pattern AND no explicit
#     test-environment marker is present (RAILS_ENV=test, NODE_ENV=test,
#     MIX_ENV=test).
#   - The deny is advisory: the user can override per-project via
#     `.claude/settings.json` permissions.allow, or run the command in
#     their own shell (the hook only sees tool-invoked Bash).
#
# Reads Claude Code hook JSON from stdin; emits JSON on stdout when blocking.

set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')
[[ -n $cmd ]] || exit 0

# Lowercase copy for case-insensitive matching via bash builtins (no subshells).
# Avoids ${cmd,,} (bash 4+ only) and shopt -s nocasematch (version quirks).
cmd_lc=$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')

# Allowlist: if the command explicitly opts into a test environment, let it
# through. Inheriting RAILS_ENV from the shell does not count — the marker
# must be in the command itself.
[[ $cmd_lc =~ (^|[[:space:]])(rails_env|node_env|mix_env|rack_env)=test([[:space:]]|$) ]] && exit 0
[[ $cmd_lc =~ (^|[[:space:]])django_settings_module=[^[:space:]]*test ]]                  && exit 0

# Destructive patterns across common stacks (written in lowercase ERE).
# `\b` boundaries to avoid matching inside paths.
# Tested with bash [[ =~ ]] — no subprocess per pattern.
patterns=(
  # Rails / Rake / bin/rails (db:reset, db:drop, db:setup, db:schema:load)
  # \b not supported in bash ERE; use ([^[:alnum:]_]|$) for end-of-word
  '(rails|rake|bin/rails)[[:space:]]+db:(reset|drop|setup|schema:load|nuke)([^[:alnum:]_]|$)'
  # Django
  'manage\.py[[:space:]]+(flush|reset_db|sqlflush)([^[:alnum:]_]|$)'
  # Prisma
  'prisma[[:space:]]+migrate[[:space:]]+reset([^[:alnum:]_]|$)'
  'prisma[[:space:]]+db[[:space:]]+push[^&|;]*--force-reset([^[:alnum:]_]|$)'
  'prisma[[:space:]]+db[[:space:]]+seed[^&|;]*--reset([^[:alnum:]_]|$)'
  # Sequelize CLI
  'sequelize[[:space:]]+db:drop([^[:alnum:]_]|$)'
  'sequelize[[:space:]]+db:migrate:undo:all([^[:alnum:]_]|$)'
  # TypeORM
  'typeorm[[:space:]]+schema:drop([^[:alnum:]_]|$)'
  # Knex
  'knex[[:space:]]+migrate:rollback[[:space:]]+--all([^[:alnum:]_]|$)'
  # PostgreSQL — (^|[^[:alnum:]_]) for start-of-word too
  '(^|[^[:alnum:]_])dropdb([^[:alnum:]_]|$)'
  # MySQL admin
  'mysqladmin[[:space:]]+([^&|;]*[[:space:]])?drop([^[:alnum:]_]|$)'
  # Raw SQL escaping into shell context
  'drop[[:space:]]+(database|schema)([^[:alnum:]_]|$)'
  'truncate([[:space:]]+table)?([^[:alnum:]_]|$)'
)

for p in "${patterns[@]}"; do
  if [[ $cmd_lc =~ $p ]]; then
    matched="$p"
    reason="Destructive database operation blocked by the db-safety guard.

Matched pattern: $matched
Command: $cmd

This pattern wipes data unconditionally and is rarely the right move during
automated work. Transient DDL/schema errors (e.g. \"Table definition has
changed\") are environment noise, not code bugs — do not \"recover\" from
them with a destructive reset.

If a reset is genuinely needed:
  1. Run the command yourself in your shell (this guard only blocks
     tool-invoked Bash), or
  2. Run with an explicit test-environment marker:
       RAILS_ENV=test <command>     # or NODE_ENV=test / MIX_ENV=test
  3. Add a per-project allow rule in .claude/settings.json:
       permissions.allow: [\"Bash(<the specific command>:*)\"]

For sub-agents: do NOT escalate to a destructive command to clear a flaky
test. Stop and report the failing command + error to the parent."

    jq -n --arg reason "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi
done

exit 0
