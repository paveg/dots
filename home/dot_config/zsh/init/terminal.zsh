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

# Ensure TERM matches tmux default-terminal when inside tmux.
# A herdr server launched from inside tmux passes TMUX down to its panes,
# so require the pane to NOT be herdr's before applying the tmux fix.
if [[ -n "$TMUX" && -z "$HERDR_ENV" && -z "$HERDR_PANE_ID" ]] && [[ "$TERM" != "screen-256color" ]]; then
  export TERM=screen-256color
fi
