# ghq-fzf.zsh — ghq + fzf repository navigation
# Provides:     ghq, _fzf_cd_ghq, repos, _GHQ_CACHE
# Requires:     ghq, fzf, bat (preview), eza (fallback)
# Side-effects: 起動時に _ghq_cache_update を背景実行 (キャッシュなし時のみ)。
#               zle widget _fzf_cd_ghq を ^g に bind。alias repos 追加
# Load-order:   AFTER plugins (zle が利用可能)

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

  # Save original buffer state for restoration on cancel
  local orig_buffer="$BUFFER"
  local orig_cursor="$CURSOR"

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
    BUFFER="$orig_buffer"
    CURSOR="$orig_cursor"
    zle reset-prompt
    return 0
  fi

  local dir="$root/$repo"
  if [[ -d "$dir" ]]; then
    # Execute cd directly instead of through BUFFER
    # This avoids issues with stray input being left in the zle buffer
    cd "$dir"
    zle reset-prompt
  else
    BUFFER="$orig_buffer"
    CURSOR="$orig_cursor"
    zle -M "Directory not found: $dir"
    zle reset-prompt
  fi
}
zle -N _fzf_cd_ghq
bindkey '^g' _fzf_cd_ghq
alias repos='_fzf_cd_ghq'
