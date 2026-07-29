# aqua-token-sync.zsh — refresh aqua's keyring GitHub token from gh
# Provides:     aqua-token-sync
# Requires:     gh, aqua
# Side-effects: writes gh's OAuth token into the OS keychain via `aqua token set`

function aqua-token-sync {
  emulate -L zsh
  setopt local_options no_xtrace

  if (( ! $+commands[gh] || ! $+commands[aqua] )); then
    print -u2 -- "aqua-token-sync: gh and aqua are required"
    return 127
  fi

  local token
  token="$(command gh auth token 2>/dev/null)" || {
    print -u2 -- "aqua-token-sync: gh auth token failed — run \`gh auth login\` first"
    return 1
  }
  if [[ -z "$token" ]]; then
    print -u2 -- "aqua-token-sync: gh returned an empty token"
    return 1
  fi

  if print -r -- "$token" | command aqua token set --stdin; then
    print -- "aqua-token-sync: keyring token updated from gh"
  else
    print -u2 -- "aqua-token-sync: aqua token set failed"
    return 1
  fi
}
