#!/usr/bin/env zsh
# wt interactive launcher for tmux display-popup
# Usage: zsh wt-interactive.zsh [dir]

local dir="${1:-$PWD}"
cd "$dir" 2>/dev/null || exit 1

source "${0:A:h}/functions.zsh"

local items
items=$(_wt_list_names)
[[ -z "$items" ]] && items="(no worktrees)"

local reload_cmd="source ${0:A:h}/functions.zsh && cd $dir && _wt_list_names"
local add_cmd="source ${0:A:h}/functions.zsh && cd $dir && read 'b?branch: ' && wt add \$b"
local rm_cmd="source ${0:A:h}/functions.zsh && cd $dir && wt rm {1}"

local selected
selected=$(echo "$items" | fzf \
  --reverse \
  --header="enter:switch / ctrl-a:add / ctrl-d:remove" \
  --bind "ctrl-a:execute($add_cmd)+reload($reload_cmd)" \
  --bind "ctrl-d:execute($rm_cmd)+reload($reload_cmd)" \
  | awk '{print $1}')

if [[ -n "$selected" && "$selected" != "(no" ]]; then
  if ! tmux select-window -t "$selected" 2>/dev/null; then
    # Window doesn't exist — create it and switch
    local wt_dir
    wt_dir=$(_wt_dir "$selected")
    tmux new-window -n "$selected" -c "$wt_dir"
    tmux set-option -w automatic-rename off
  fi
fi
exit 0
