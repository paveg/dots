# mise.zsh — mise (rtx) runtime version manager activation
# Provides:     PATH (mise shims), mise function
# Requires:     mise (optional — no-op if absent)
# Side-effects: cache and source the output of 'mise activate zsh'
# Load-order:   AFTER homebrew (when mise is installed via brew), BEFORE auto-mux

# mise (runtime version manager) - early activation for tmux
# Must be activated before auto_mux to ensure the multiplexer is in PATH
if command -v mise &>/dev/null; then
  _mise_cache="$ZSH_INIT_CACHE/mise.zsh"
  # `mise activate` embeds the current PATH in its output. Include that input
  # in the fingerprint so adding or removing a tool path invalidates the cache.
  if _zsh_command_cache_prepare \
    "$_mise_cache" \
    "mise-activate-v2|path=${PATH}" \
    mise \
    activate zsh; then
    source "$_mise_cache"
  fi
fi
unset _mise_cache
