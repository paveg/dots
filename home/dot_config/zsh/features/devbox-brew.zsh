# devbox-brew.zsh - wrap devbox to persist global changes via chezmoi; dump Brewfile
# Provides:     devbox, brewbundle
# Requires:     devbox, chezmoi, brew
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
  local source_hint="${CHEZMOI_SOURCE_DIR:-}"
  local source_dir
  local brewfile

  if [[ -n "$source_hint" ]]; then
    source_dir="$(chezmoi --source "$source_hint" source-path 2>/dev/null)" || {
      echo "Could not resolve the chezmoi source directory from CHEZMOI_SOURCE_DIR: $source_hint" >&2
      return 1
    }
  else
    source_dir="$(chezmoi source-path 2>/dev/null)" || {
      echo "Could not resolve the active chezmoi source directory." >&2
      return 1
    }
  fi

  if [[ -z "$source_dir" ]]; then
    echo "chezmoi returned an empty source directory." >&2
    return 1
  fi

  if [[ -n "$BUSINESS_USE" ]]; then
    brewfile="$source_dir/homebrew/Brewfile.work"
  else
    brewfile="$source_dir/homebrew/Brewfile"
  fi
  if [[ ! -f "$brewfile" ]]; then
    echo "Brewfile not found: $brewfile" >&2
    return 1
  fi
  brew bundle dump --force --file="$brewfile"
  echo "Updated: $brewfile"
}
