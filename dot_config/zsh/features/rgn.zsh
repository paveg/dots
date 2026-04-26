# ripgrep + fzf -> nvim (live grep, multi-select, open at line)
# Usage: rgn [pattern]        # typing live-reloads rg
#        Tab                  # multi-select matches
#        Enter                # open selected file(s) in nvim at the match line
#        Alt-/                # toggle preview
# Keybinding: Alt+R
rgn() {
  if ! (( $+commands[rg] && $+commands[fzf] )); then
    echo "Error: rgn requires rg and fzf" >&2
    return 1
  fi

  local rg_cmd='rg --column --line-number --no-heading --color=always --smart-case'
  local initial="${*:-}"
  local selections

  # : | ... starts fzf with an empty list; start/change bindings drive rg.
  selections=$(
    : | fzf --ansi --multi \
        --disabled --query "$initial" \
        --delimiter : --prompt 'rg> ' \
        --header 'Tab: multi-select / Enter: open / Alt-/: toggle preview' \
        --bind "start:reload:$rg_cmd -- {q} 2>/dev/null || true" \
        --bind "change:reload:sleep 0.1; $rg_cmd -- {q} 2>/dev/null || true" \
        --bind 'alt-/:toggle-preview' \
        --preview 'bat --color=always --style=numbers --highlight-line {2} {1} 2>/dev/null || cat {1}' \
        --preview-window 'right,60%,border-left,+{2}+3/3,~3'
  )

  [[ -z "$selections" ]] && return 0

  local -a args
  local file line
  while IFS=: read -r file line _; do
    [[ -z "$file" ]] && continue
    args+=("+${line}" "$file")
  done <<< "$selections"

  (( ${#args[@]} > 0 )) && ${EDITOR:-nvim} -p "${args[@]}"
}

# Alt+R: launch rgn from anywhere on the command line
_rgn_widget() {
  BUFFER='rgn'
  zle accept-line
}
zle -N _rgn_widget
bindkey '^[r' _rgn_widget
