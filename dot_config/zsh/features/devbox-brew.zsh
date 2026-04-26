# Devbox wrapper - auto re-add to chezmoi after global changes
devbox() {
  command devbox "$@"
  local ret=$?

  # Re-add devbox global config to chezmoi after modifying commands
  if [[ "$1" == "global" ]] && [[ "$2" =~ ^(add|rm|install|remove|update)$ ]]; then
    local devbox_global="${HOME}/.local/share/devbox/global/default"
    if [[ -f "${devbox_global}/devbox.json" ]]; then
      chezmoi re-add "${devbox_global}/devbox.json" "${devbox_global}/devbox.lock" 2>/dev/null
      echo "📦 chezmoi re-add: devbox.json, devbox.lock"
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
