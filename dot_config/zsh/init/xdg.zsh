# xdg.zsh — XDG Base Directory env vars (fallback for non-zshenv shells)
# Provides:     XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_CACHE_HOME, XDG_STATE_HOME
# Requires:     なし
# Side-effects: 上記 4 環境変数を export
# Load-order:   FIRST (他の init/* がこれらを参照)

# XDG Base Directory (fallback if .zshenv not sourced)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
