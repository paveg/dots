# terminal.zsh — TERM compatibility shimming
# Provides:     TERM (補正値)
# Requires:     infocmp (任意)
# Side-effects: TERM を xterm-256color または screen-256color に上書きする条件あり
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
