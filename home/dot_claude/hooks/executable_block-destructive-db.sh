#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny destructive database operations by default.
#
# Why: a tool-invoked `db:reset` (or equivalent across stacks) wipes data
# unconditionally. The same command targets development by default in most
# ORMs, so a wrong run during automated work destroys the developer's local
# DB. Recovery is hours; pausing is zero.
#
# Behavior:
#   - Deny every known destructive database operation, even when the command
#     contains a test-environment marker.
#   - Inspect a conservative quote/backslash-normalized copy so simple shell
#     token concatenation cannot hide a known destructive operation.
#   - Runner-to-task matching may cross control operators. A command that only
#     prints both strings can be paused; issue those diagnostics separately.
#   - The deny is advisory: the user can override per-project via
#     `.claude/settings.json` permissions.allow, or run the command in
#     their own shell (the hook only sees tool-invoked Bash).
#   - This is not a shell AST/dataflow evaluator. Agent rules prohibit
#     dynamically constructing destructive DB commands.
#
# Reads Claude Code hook JSON from stdin; emits JSON on stdout when blocking.

set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')
[[ -n $cmd ]] || exit 0

# Destructive patterns across common stacks (written in lowercase ERE).
# Explicit non-identifier boundaries avoid substring matches. Runner-to-task
# spans are intentionally broad so quoted/escaped shell separators inside CLI
# option values cannot hide the destructive operation. This also crosses real
# control operators by design; fail-closed review is safer than a shell parser.
# \b is not supported in bash ERE; use ([^[:alnum:]_]|$) for word ends.
patterns=(
  '(rails|rake|bin/rails)[[:space:]]+.*db:(reset|drop|setup|schema:load|nuke)([^[:alnum:]_]|$)'
  'manage\.py[[:space:]]+.*(flush|reset_db|sqlflush)([^[:alnum:]_]|$)'
  'prisma[[:space:]]+.*migrate[[:space:]]+reset([^[:alnum:]_]|$)'
  'prisma[[:space:]]+.*db[[:space:]]+push.*--force-reset([^[:alnum:]_]|$)'
  'prisma[[:space:]]+.*db[[:space:]]+seed.*--reset([^[:alnum:]_]|$)'
  'sequelize[[:space:]]+.*db:drop([^[:alnum:]_]|$)'
  'sequelize[[:space:]]+.*db:migrate:undo:all([^[:alnum:]_]|$)'
  'typeorm[[:space:]]+.*schema:drop([^[:alnum:]_]|$)'
  'knex[[:space:]]+.*migrate:rollback[[:space:]]+.*--all([^[:alnum:]_]|$)'
  '(^|[^[:alnum:]_])dropdb([^[:alnum:]_]|$)'
  'mysqladmin[[:space:]]+(.*[[:space:]])?drop([^[:alnum:]_]|$)'
  'drop[[:space:]]+(database|schema)([^[:alnum:]_]|$)'
  'truncate([[:space:]]+table)?([^[:alnum:]_]|$)'
)

deny_command() {
  local matched=$1
  local reason

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
  2. Add a narrowly scoped per-project allow rule in .claude/settings.json:
       permissions.allow: [\"Bash(<the specific command>:*)\"]

Test-environment markers are not an automatic exception: they do not prove
which datasource a framework or raw database client will actually target.

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
}

# Conservatively join every backslash-newline and remove quote/backslash
# concatenation before deny matching. Over-normalization can only produce a
# pause for review; there is no automatic allow path.
cmd_scan=${cmd//$'\\\n'/}
cmd_scan=${cmd_scan//\"/}
cmd_scan=${cmd_scan//\'/}
cmd_scan=${cmd_scan//\\/}
cmd_scan_lc=$(printf '%s' "$cmd_scan" | tr '[:upper:]' '[:lower:]')

for i in "${!patterns[@]}"; do
  p=${patterns[$i]}
  [[ $cmd_scan_lc =~ $p ]] && deny_command "$p"
done

exit 0
