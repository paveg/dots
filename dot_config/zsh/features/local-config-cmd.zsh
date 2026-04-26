local-env() {
  local file="$HOME/.env.local"
  case "$1" in
    edit)
      [[ ! -f "$file" ]] && echo "# Machine-specific environment variables" > "$file"
      ${EDITOR:-nvim} "$file"
      echo "Run 'source ~/.env.local' or restart shell to apply changes"
      ;;
    show)
      if [[ -f "$file" ]]; then
        echo "=== ~/.env.local ==="
        cat "$file"
      else
        echo "~/.env.local does not exist. Run 'local-env edit' to create."
      fi
      ;;
    *)
      echo "Usage: local-env <command>"
      echo ""
      echo "Commands:"
      echo "  edit    Edit ~/.env.local (environment variables)"
      echo "  show    Show current ~/.env.local contents"
      echo ""
      echo "Related files:"
      echo "  ~/.env.local     - Environment variables (export VAR=value)"
      echo "  ~/.zshrc.local   - Shell config (aliases, functions)"
      echo "  .envrc           - Per-directory env (direnv)"
      ;;
  esac
}

local-zsh() {
  local file="$HOME/.zshrc.local"
  case "$1" in
    edit)
      if [[ ! -f "$file" ]]; then
        cat > "$file" << 'EOF'
# Machine-specific zsh configuration
# This file is sourced at the end of ~/.zshrc

# Example:
# alias myalias='some-command'
# export PATH="$HOME/custom/bin:$PATH"
EOF
      fi
      ${EDITOR:-nvim} "$file"
      echo "Run 'source ~/.zshrc.local' or restart shell to apply changes"
      ;;
    show)
      if [[ -f "$file" ]]; then
        echo "=== ~/.zshrc.local ==="
        cat "$file"
      else
        echo "~/.zshrc.local does not exist. Run 'local-zsh edit' to create."
      fi
      ;;
    *)
      echo "Usage: local-zsh <command>"
      echo ""
      echo "Commands:"
      echo "  edit    Edit ~/.zshrc.local (shell config)"
      echo "  show    Show current ~/.zshrc.local contents"
      ;;
  esac
}
