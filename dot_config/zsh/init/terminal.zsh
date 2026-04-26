# terminal.zsh — TERM compatibility shimming
# Provides:     TERM (corrected value)
# Requires:     infocmp (optional)
# Side-effects: conditionally override TERM to xterm-256color or screen-256color
# Load-order:   AFTER xdg

# Terminal compatibility
# Fall back to xterm-256color if terminfo is missing (e.g., SSH to older servers)
if [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty &>/dev/null; then
  export TERM=xterm-256color
fi

# Ensure TERM matches tmux default-terminal when inside tmux
if [[ -n "$TMUX" ]] && [[ "$TERM" != "screen-256color" ]]; then
  export TERM=screen-256color
fi
