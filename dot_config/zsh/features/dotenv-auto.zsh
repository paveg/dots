# Auto-load .env files (fallback when no .envrc exists)
# Note: If .envrc exists, direnv handles everything (use dotenv_if_exists in .envrc)
# This hook only activates when .env exists but .envrc doesn't

_dotenv_loaded_dir=""

_auto_dotenv() {
  # Skip if direnv will handle this directory
  [[ -f ".envrc" ]] && return

  # Load .env if exists
  if [[ -f ".env" ]]; then
    if [[ "$_dotenv_loaded_dir" != "$PWD" ]]; then
      # shellcheck disable=SC1091
      set -a
      source ".env"
      set +a
      _dotenv_loaded_dir="$PWD"
    fi
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _auto_dotenv
