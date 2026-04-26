# local-config.zsh — load machine-specific overrides
# Provides:     none (vars/functions defined by ~/.env.local and ~/.zshrc.local)
# Requires:     ~/.env.local, ~/.zshrc.local (optional — no-op if absent)
# Side-effects: source ~/.env.local; source ~/.zshrc.local
# Load-order:   AFTER all features/* (so local overrides can shadow features)

# Local environment variables (not managed by chezmoi)
# Priority: .env.local -> .zshrc.local (both are gitignored)

# Machine-specific environment variables
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# Machine-specific shell configuration
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
