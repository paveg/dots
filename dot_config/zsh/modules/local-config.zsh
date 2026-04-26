# Local environment variables (not managed by chezmoi)
# Priority: .env.local -> .zshrc.local (both are gitignored)

# Machine-specific environment variables
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# Machine-specific shell configuration
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
