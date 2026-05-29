# Devbox wrapper - persist global changes back to chezmoi after mutations
devbox() {
  command devbox "$@"
  local ret=$?

  if [[ "$1" == "global" ]] && [[ "$2" =~ ^(add|rm|install|remove|update)$ ]]; then
    local json="${HOME}/.local/share/devbox/global/default/devbox.json"
    local src
    src="$(chezmoi source-path "$json" 2>/dev/null)"

    if [[ "$src" == *.tmpl ]]; then
      # chezmoi re-add silently skips template sources, so it can't round-trip
      # the business/personal split — edit the template by hand instead.
      echo "⚠ devbox.json is a chezmoi template — change NOT auto-persisted." >&2
      echo "  Update ${src} (personal packages: the 'not .business_use' block)." >&2
    elif [[ -n "$src" ]]; then
      chezmoi re-add "$json" 2>/dev/null && echo "📦 chezmoi re-add: devbox.json"
    fi
  fi

  return $ret
}

# Brewfile management (macOS)
brewbundle() {
  local chezmoi_dir="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
  local brewfile
  if [[ -n "$BUSINESS_USE" ]]; then
    brewfile="$chezmoi_dir/homebrew/Brewfile.work"
  else
    brewfile="$chezmoi_dir/homebrew/Brewfile"
  fi
  [[ ! -f "$brewfile" ]] && echo "Brewfile not found: $brewfile" && return 1
  brew bundle dump --force --file="$brewfile"
  echo "Updated: $brewfile"
}
