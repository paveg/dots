# vite-plus.zsh — Vite+ env loader
# Provides:     なし (~/.vite-plus/env が定義する変数)
# Requires:     ~/.vite-plus/env (任意 — 不在時は no-op)
# Side-effects: source ~/.vite-plus/env
# Load-order:   free

# Vite+ bin
[[ -f "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
