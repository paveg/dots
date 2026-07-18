#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny git commands that skip commit/tag signing.
#
# Why: commit.gpgsign=true is the contract; when 1Password signing fails
# (locked app, headless SSH / Remote Control session without a forwarded
# agent), the tempting fallback is `--no-gpg-sign` or turning gpgsign off,
# which silently ships unsigned commits. Failing loudly here turns that
# into a visible decision.
#
# Threat model is the model's own lazy fallback, not a determined adversary.
# Heredoc bodies and quoted strings are stripped before matching so prose
# that merely mentions the flags (commit messages, PR bodies, grep patterns)
# does not trigger the guard. Known accepted gaps: flags hidden by variable
# concatenation, line continuations, GIT_CONFIG_PARAMETERS, or quoting the
# flag itself.
#
# Reads Claude Code hook JSON from stdin; emits JSON on stdout when blocking.

set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')
[[ -n $cmd ]] || exit 0

cmd_code=$(printf '%s\n' "$cmd" | awk '
  inhd {
    line = $0
    if (dash) sub(/^\t+/, "", line)
    if (line == delim) inhd = 0
    next
  }
  match($0, /<<-?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z_0-9]*/) {
    op = substr($0, RSTART, RLENGTH)
    dash = (op ~ /^<<-/)
    delim = op
    sub(/<<-?[[:space:]]*['\''"]?/, "", delim)
    inhd = 1
    print
    next
  }
  { print }
' | sed -E "s/'[^']*'//g" | sed -E 's/"[^"]*"//g')

# Only guard commands that invoke git as a word (not .github, .gitignore).
grep -qE '(^|[^[:alnum:]_])git([^[:alnum:]_]|$)' <<<"$cmd_code" || exit 0

if grep -qE -e '--no-gpg-sign|gpgsign[[:space:]=]+false' <<<"$cmd_code"; then
  reason="Unsigned commits are blocked (commit.gpgsign=true is the contract).

Signing usually fails here because 1Password is unreachable:
  - Over SSH: connect with agent forwarding from a device running 1Password
    (ForwardAgent yes); op-ssh-sign then authorizes on that device.
  - Remote Control / headless: the 1Password app on this machine must be
    unlocked; there is no headless unlock. Defer the commit, or run it
    later from an interactive session.

If an unsigned commit is genuinely intended, run the command yourself in
your own shell (this guard only blocks tool-invoked Bash)."

  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

exit 0
