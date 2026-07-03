# auto-mux.zsh — auto-attach/create terminal multiplexer (tmux or herdr) on startup
# Provides:     auto_mux (invoked at load time)
# Requires:     tmux or herdr (per selection), fzf (optional)
# Side-effects: exec replaces the shell process; must run before p10k.
#               Selection: $AUTO_MUX > ~/.config/auto-mux file > tmux.
#               Values: tmux | herdr | none. DISABLE_AUTO_TMUX=1 = legacy none.
#               ~/.zshrc.local loads AFTER the exec, so it cannot switch this —
#               use the state file or set AUTO_MUX in the terminal's env instead.
# Load-order:   AFTER mise (so tmux is in PATH), BEFORE p10k-instant

auto_mux() {
  # Skip if already inside a multiplexer (either one)
  [[ -n "$TMUX" || -n "$HERDR_SESSION" || -n "$HERDR_PANE_ID" ]] && return 0
  # Skip if not interactive
  [[ ! -o interactive ]] && return 0
  # Skip if explicitly disabled
  [[ "${DISABLE_AUTO_TMUX:-0}" = "1" ]] && return 0
  # Skip in CI/Docker
  [[ -n "$CI" || -n "$CONTAINER" || -f /.dockerenv ]] && return 0

  local mux="${AUTO_MUX:-}"
  if [[ -z "$mux" ]]; then
    local state_file="${XDG_CONFIG_HOME:-$HOME/.config}/auto-mux"
    [[ -r "$state_file" ]] && mux="$(<"$state_file")"
  fi

  case "${mux:-tmux}" in
    none)
      return 0
      ;;
    herdr)
      (( $+commands[herdr] )) && exec herdr
      ;;
    tmux|*)
      (( $+commands[tmux] )) || return 0
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
      ;;
  esac
}
auto_mux
