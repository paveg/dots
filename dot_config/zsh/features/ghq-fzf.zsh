# ghq-fzf.zsh — ghq + fzf repository navigation
# Provides:     ghq, _fzf_cd_ghq, repos, _GHQ_CACHE
# Requires:     ghq, fzf, bat (preview), eza (fallback)
# Side-effects: run _ghq_cache_update in background at load (only when cache is missing).
#               Bind zle widget _fzf_cd_ghq to ^g. Add 'repos' alias.
# Load-order:   AFTER plugins (so zle is available)

# ghq + fzf repository navigation (cached for speed)
_GHQ_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ghq_list"

# Update ghq cache in background
_ghq_cache_update() {
  command ghq list > "$_GHQ_CACHE" 2>/dev/null
}

# Initialize cache on shell startup (background, non-blocking)
if [[ ! -f "$_GHQ_CACHE" ]]; then
  mkdir -p "$(dirname "$_GHQ_CACHE")"
  _ghq_cache_update &!
fi

# ghq wrapper: auto-update cache when repos change
ghq() {
  local subcmd="$1"
  command ghq "$@"
  local ret=$?

  # Update cache after repo-modifying commands
  case "$subcmd" in
    get|create|rm)
      _ghq_cache_update &!
      ;;
  esac

  return $ret
}

_fzf_cd_ghq() {
  local root repo
  root="$(command ghq root 2>/dev/null)" || return 1

  # $WIDGET is only set when invoked via zle (e.g. via the ^g binding).
  # When called as a plain command (e.g. via the `repos` alias), zle is not
  # active, so accessing BUFFER/CURSOR or calling `zle ...` would fail.
  local in_widget=0
  [[ -n "$WIDGET" ]] && in_widget=1

  local orig_buffer orig_cursor
  if (( in_widget )); then
    orig_buffer="$BUFFER"
    orig_cursor="$CURSOR"
  fi

  # Ensure cache exists
  [[ ! -f "$_GHQ_CACHE" ]] && _ghq_cache_update

  local preview_cmd='
    repo_path='"$root"'/{}
    if [[ -f $repo_path/README.md ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README.md 2>/dev/null
    elif [[ -f $repo_path/README.rst ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README.rst 2>/dev/null
    elif [[ -f $repo_path/README ]]; then
      bat --color=always --style=header,grid --line-range :80 $repo_path/README 2>/dev/null
    else
      echo Contents:
      eza -la $repo_path 2>/dev/null | head -n 15
    fi
  '

  repo="$(cat "$_GHQ_CACHE" 2>/dev/null | \
    fzf --reverse --height=80% \
        --header='Ctrl+R: refresh cache' \
        --bind="ctrl-r:reload(command ghq list | tee $_GHQ_CACHE)" \
        --preview="$preview_cmd" \
        --preview-window=right:50%)"

  # Handle ESC or empty selection - restore original buffer
  if [[ -z "$repo" ]]; then
    if (( in_widget )); then
      BUFFER="$orig_buffer"
      CURSOR="$orig_cursor"
      zle reset-prompt
    fi
    return 0
  fi

  local dir="$root/$repo"
  if [[ -d "$dir" ]]; then
    # Execute cd directly instead of through BUFFER
    # This avoids issues with stray input being left in the zle buffer
    cd "$dir"
    (( in_widget )) && zle reset-prompt
  else
    if (( in_widget )); then
      BUFFER="$orig_buffer"
      CURSOR="$orig_cursor"
      zle -M "Directory not found: $dir"
      zle reset-prompt
    else
      echo "Directory not found: $dir" >&2
    fi
  fi
}
zle -N _fzf_cd_ghq
bindkey '^g' _fzf_cd_ghq
alias repos='_fzf_cd_ghq'
