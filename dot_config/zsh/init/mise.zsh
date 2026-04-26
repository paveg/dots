# mise.zsh — mise (rtx) runtime version manager activation
# Provides:     PATH (mise shims), mise function
# Requires:     mise (任意 — 不在時は no-op)
# Side-effects: mise activate zsh の出力をキャッシュ&source
# Load-order:   AFTER homebrew (mise が brew で入る場合), BEFORE auto-tmux

# mise (runtime version manager) - early activation for tmux
# Must be activated before auto_tmux to ensure tmux is in PATH
if command -v mise &>/dev/null; then
  _mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/mise.zsh"
  # Invalidate cache when mise version changes
  _mise_ver="$(mise --version 2>/dev/null)"
  if [[ ! -f "$_mise_cache" ]] || ! grep -qF "# mise $_mise_ver" "$_mise_cache" 2>/dev/null; then
    mkdir -p "$(dirname "$_mise_cache")"
    { echo "# mise $_mise_ver"; mise activate zsh; } > "$_mise_cache"
  fi
  source "$_mise_cache"
  unset _mise_cache _mise_ver
fi
