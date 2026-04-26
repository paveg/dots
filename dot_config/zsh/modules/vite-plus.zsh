# vite-plus.zsh — Vite+ env loader
# Provides:     none (vars defined by ~/.vite-plus/env)
# Requires:     ~/.vite-plus/env (optional — no-op if absent)
# Side-effects: source ~/.vite-plus/env
# Load-order:   free

# Vite+ bin
[[ -f "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
