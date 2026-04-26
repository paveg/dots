# auto-tmux.zsh — auto-attach/create tmux on terminal startup
# Provides:     auto_tmux (invoked at load time)
# Requires:     tmux, fzf (optional)
# Side-effects: exec replaces the shell process; must run before p10k.
#               No-op in CI/Docker (DISABLE_AUTO_TMUX=1 to disable explicitly).
# Load-order:   AFTER mise (so tmux is in PATH), BEFORE p10k-instant

# Auto tmux on terminal startup
# Must run BEFORE p10k instant prompt (exec replaces shell, breaks p10k state)
auto_tmux() {
  # Skip if already in tmux
  [[ -n "$TMUX" ]] && return 0
  # Skip if not interactive
  [[ ! -o interactive ]] && return 0
  # Skip if explicitly disabled
  [[ "${DISABLE_AUTO_TMUX:-0}" = "1" ]] && return 0
  # Skip in CI/Docker
  [[ -n "$CI" || -n "$CONTAINER" || -f /.dockerenv ]] && return 0

  if (( $+commands[tmux] )); then
    # Get existing sessions
    local sessions
    sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})

    if (( ${#sessions[@]} == 0 )); then
      # No sessions: create new
      exec tmux new-session
    elif (( ${#sessions[@]} == 1 )); then
      # Single session: attach directly
      exec tmux attach-session -t "${sessions[1]}"
    else
      # Multiple sessions: select with fzf or fallback
      local selected
      if (( $+commands[fzf] )); then
        selected=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_created_string})' 2>/dev/null \
          | fzf --height=40% --reverse --header="Select tmux session (ESC for new)" \
          | cut -d: -f1)
      else
        # Fallback: attach to first session if fzf unavailable
        selected="${sessions[1]}"
      fi

      if [[ -n "$selected" ]]; then
        exec tmux attach-session -t "$selected"
      else
        exec tmux new-session
      fi
    fi
  fi
}
auto_tmux
