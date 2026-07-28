# ghtkn-gh.zsh — provide short-lived GitHub credentials to gh
# Provides:     gh wrapper
# Requires:     gh, ghtkn
# Side-effects: invokes `ghtkn get` for each gh command without an explicit token

if (( $+aliases[gh] )); then
  unalias gh
fi

function gh {
  emulate -L zsh
  setopt local_options no_xtrace

  # Preserve explicit credentials supplied by automation or the caller.
  if [[ -n ${GH_TOKEN:-} || -n ${GITHUB_TOKEN:-} ]]; then
    command gh "$@"
    return
  fi

  if (( ! $+commands[ghtkn] )); then
    print -u2 -- "gh: ghtkn is required when no explicit GitHub token is set"
    return 127
  fi

  local token
  token="$(command ghtkn get)" || return
  if [[ -z "$token" ]]; then
    print -u2 -- "gh: ghtkn returned an empty token; refusing to run gh"
    return 1
  fi

  GH_TOKEN="$token" command gh "$@"
}
