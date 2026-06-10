#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny commands that reference credential paths,
# private keys, secret files, or shell history.  Layer 2 of the
# two-layer credential-read guardrail (Layer 1 = Read/Edit deny rules in
# settings.json).
#
# Deny-biased and deliberately conservative: any *reference* to a
# credential path is blocked, regardless of whether the command is a
# read, write, or delete.
#
# To allow a legitimately needed command:
#   - Run it yourself in the terminal with the `!` prefix, or
#   - Add a scoped allow rule in .claude/settings.json for your project.
set -euo pipefail

# ── Parse input ────────────────────────────────────────────────────────────
# If jq fails or tool_name is not Bash, exit 0 (allow).
payload=$(cat)

tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""' 2>/dev/null) || { exit 0; }
[[ $tool_name == "Bash" ]] || exit 0

cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null) || { exit 0; }

# ── Helper: emit a deny decision ──────────────────────────────────────────
deny() {
  local pattern="$1"
  local reason
  reason=$(printf \
    'Credential access blocked — matched pattern: %s\n\n%s\n%s' \
    "$pattern" \
    "To run this command yourself, use the '!' prefix in Claude Code or run it directly in your terminal." \
    "If this is a false positive, add a scoped allow rule in .claude/settings.json.")
  jq -n --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# ── Pattern matching ───────────────────────────────────────────────────────
# HOME-prefixed path helper: matches ~, $HOME, or ${HOME} spellings.
# Usage: home_path_re <suffix>  (suffix is ERE, no leading /)
home() { printf '(~|\$HOME|\$\{HOME\})/%s' "$1"; }

# 1. SSH directory
[[ $cmd =~ $(home '\.ssh/') ]] && deny "$(home '.ssh/')"

# 2. AWS credentials
[[ $cmd =~ $(home '\.aws/') ]] && deny "$(home '.aws/')"

# 3. GnuPG
[[ $cmd =~ $(home '\.gnupg/') ]] && deny "$(home '.gnupg/')"

# 4. gcloud config
[[ $cmd =~ $(home '\.config/gcloud/') ]] && deny "$(home '.config/gcloud/')"

# 5. kubeconfig
[[ $cmd =~ $(home '\.kube/config') ]] && deny "$(home '.kube/config')"

# 6. Docker config
[[ $cmd =~ $(home '\.docker/config\.json') ]] && deny "$(home '.docker/config.json')"

# 7. Database / network password stores
[[ $cmd =~ $(home '\.netrc') ]]   && deny "$(home '.netrc')"
[[ $cmd =~ $(home '\.pgpass') ]]  && deny "$(home '.pgpass')"
[[ $cmd =~ $(home '\.my\.cnf') ]] && deny "$(home '.my.cnf')"

# 8. npm credentials
[[ $cmd =~ $(home '\.npmrc') ]] && deny "$(home '.npmrc')"

# 9. GitHub CLI hosts file
[[ $cmd =~ $(home '\.config/gh/hosts\.yml') ]] && deny "$(home '.config/gh/hosts.yml')"

# 10. chezmoi config
[[ $cmd =~ $(home '\.config/chezmoi/chezmoi\.yaml') ]] && deny "$(home '.config/chezmoi/chezmoi.yaml')"

# 11. Terraform credentials
[[ $cmd =~ $(home '\.terraform\.d/credentials') ]] && deny "$(home '.terraform.d/credentials')"

# 12. Shell history / atuin history
[[ $cmd =~ $(home '\.zsh_history') ]]           && deny "$(home '.zsh_history')"
[[ $cmd =~ $(home '\.local/share/atuin/') ]]    && deny "$(home '.local/share/atuin/')"

# 13. Bare SSH key filenames (anywhere in command)
[[ $cmd =~ (^|[^a-zA-Z0-9_])(id_rsa|id_ed25519|id_ecdsa)([^a-zA-Z0-9_]|$) ]] \
  && deny "bare key filename (id_rsa|id_ed25519|id_ecdsa)"

# 14. .env files — but NOT .env.example / .env.sample / .env.template
#     Strategy: strip the three safe suffixes, then test the remainder.
cmd_stripped="${cmd//.env.example/}"
cmd_stripped="${cmd_stripped//.env.sample/}"
cmd_stripped="${cmd_stripped//.env.template/}"
# Match \b.env\b  or  .env. (prefix of other variants like .env.local)
# Also match .envrc (direnv files often export secrets)
[[ $cmd_stripped =~ (^|[^a-zA-Z0-9_])\.env(\.|[^a-zA-Z0-9_]|$) ]] \
  && deny ".env file (use .env.example / .env.sample / .env.template for non-secret examples)"
[[ $cmd_stripped =~ (^|[^a-zA-Z0-9_])\.envrc(\b|$) ]] \
  && deny ".envrc (direnv config often exports secrets)"

# 15. Certificate / key container formats
[[ $cmd =~ \.(pem|p12|pfx|keystore|jks)(\ |$|\"|\'|;) ]] \
  && deny ".pem/.p12/.pfx/.keystore/.jks file"

# 16. Service account / secret files
[[ $cmd =~ credentials[^/]*\.json ]]        && deny "credentials*.json"
[[ $cmd =~ service-account[^/]*\.json ]]    && deny "service-account*.json"
[[ $cmd =~ secrets\.(json|ya?ml) ]]         && deny "secrets.(json|yaml|yml)"

# 17. macOS keychain dumping
[[ $cmd =~ security[[:space:]]+(find-generic-password|find-internet-password|dump-keychain) ]] \
  && deny "macOS keychain access (security find-generic-password|find-internet-password|dump-keychain)"

# ── No match — allow ───────────────────────────────────────────────────────
exit 0
