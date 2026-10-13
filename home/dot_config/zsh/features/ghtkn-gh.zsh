# ghtkn-gh.zsh — run gh with a short-lived GitHub App token from the ghtkn agent
# Provides:     gh
# Requires:     gh, ghtkn (agent unlocked)
# Side-effects: runs gh through `ghtkn exec` unless GH_TOKEN or GITHUB_TOKEN is set

if (( $+aliases[gh] )); then
  unalias gh
fi

function gh {
  emulate -L zsh
  setopt local_options no_xtrace

  if [[ -n ${GH_TOKEN:-} || -n ${GITHUB_TOKEN:-} ]]; then
    command gh "$@"
    return
  fi

  if (( ! $+commands[ghtkn] )); then
    print -u2 -- "gh: ghtkn is required when no explicit GitHub token is set"
    return 127
  fi

  command ghtkn exec -e GH_TOKEN:C-FO/write -- gh "$@"
  local exit_status=$?
  if (( exit_status == 111 )); then
    print -u2 -- "gh: no ghtkn token available — run \`ghtkn agent unlock --enable-refresh\`"
  fi
  return $exit_status
}
