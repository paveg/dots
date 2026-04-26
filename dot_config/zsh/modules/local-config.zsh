# local-config.zsh — load machine-specific overrides
# Provides:     なし (~/.env.local / ~/.zshrc.local が定義する変数や関数)
# Requires:     ~/.env.local, ~/.zshrc.local (任意 — 不在時は no-op)
# Side-effects: source ~/.env.local; source ~/.zshrc.local
# Load-order:   AFTER 全 features/* (local override が機能を上書きできるよう最後に)

# Local environment variables (not managed by chezmoi)
# Priority: .env.local -> .zshrc.local (both are gitignored)

# Machine-specific environment variables
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# Machine-specific shell configuration
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
