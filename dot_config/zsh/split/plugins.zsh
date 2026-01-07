# =============================================================================
# Zinit
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# Turbo-loaded plugins
# =============================================================================
zinit wait lucid blockf light-mode for \
  atload"zicompinit; zicdreplay" \
    zsh-users/zsh-completions

zinit wait lucid light-mode for \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting

zinit wait lucid light-mode for \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search

# =============================================================================
# Powerlevel10k prompt
# =============================================================================
zinit ice depth=1
zinit light romkatv/powerlevel10k

# =============================================================================
# Tool initialization (turbo mode)
# =============================================================================
_zsh_cache="${XDG_CACHE_HOME}/zsh/init"
[[ -d "$_zsh_cache" ]] || mkdir -p "$_zsh_cache"

# zoxide (turbo)
_zinit_setup_zoxide() {
  if (( $+commands[zoxide] )); then
    local _zoxide_cache="${XDG_CACHE_HOME}/zsh/init/zoxide.zsh"
    [[ -f "$_zoxide_cache" ]] || zoxide init zsh > "$_zoxide_cache"
    source "$_zoxide_cache"
  fi
}

zinit wait"1" lucid light-mode for \
  atload"_zinit_setup_zoxide" \
    zdharma-continuum/null

# atuin (turbo) - shell history (load after fzf to override Ctrl+R)
_zinit_setup_atuin() {
  if (( $+commands[atuin] )); then
    local _atuin_cache="${XDG_CACHE_HOME}/zsh/init/atuin.zsh"
    [[ -f "$_atuin_cache" ]] || atuin init zsh --disable-up-arrow > "$_atuin_cache"
    source "$_atuin_cache"
  fi
}

zinit wait"2" lucid light-mode for \
  atload"_zinit_setup_atuin" \
    zdharma-continuum/null

# fzf (turbo)
_zinit_setup_fzf() {
  if (( $+commands[fzf] )); then
    local _fzf_cache="${XDG_CACHE_HOME}/zsh/init/fzf.zsh"
    [[ -f "$_fzf_cache" ]] || fzf --zsh > "$_fzf_cache"
    source "$_fzf_cache"

    # Tokyo Night colors
    export FZF_DEFAULT_OPTS=" \
      --height 60% --layout=reverse --border=rounded \
      --margin=1 --padding=1 \
      --color=bg+:#292e42,bg:#1a1b26,spinner:#9ece6a,hl:#7aa2f7 \
      --color=fg:#c0caf5,header:#7aa2f7,info:#7dcfff,pointer:#f7768e \
      --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7dcfff,hl+:#7aa2f7 \
      --color=selected-bg:#33467c \
      --preview-window=right:50%:border-left \
      --bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"

    # File search (Ctrl+T)
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :300 {} 2>/dev/null || cat {}'"

    # Directory search (Alt+C)
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --level=2 --color=always {} | head -n 50'"

    # Note: Ctrl+R history search is handled by atuin
  fi
}

zinit wait"1" lucid light-mode for \
  atload"_zinit_setup_fzf" \
    zdharma-continuum/null

# direnv (turbo)
_zinit_setup_direnv() {
  if (( $+commands[direnv] )); then
    local _direnv_cache="${XDG_CACHE_HOME}/zsh/init/direnv.zsh"
    [[ -f "$_direnv_cache" ]] || direnv hook zsh > "$_direnv_cache"
    source "$_direnv_cache"
  fi
}

zinit wait"2" lucid light-mode for \
  atload"_zinit_setup_direnv" \
    zdharma-continuum/null

# =============================================================================
# Tool completions (cached, turbo mode)
# =============================================================================
_completions_cache="${XDG_CACHE_HOME}/zsh/completions"
[[ -d "$_completions_cache" ]] || mkdir -p "$_completions_cache"

_zinit_setup_completions() {
  local cache_dir="${XDG_CACHE_HOME}/zsh/completions"

  # gh (GitHub CLI)
  if (( $+commands[gh] )); then
    local _gh_comp="$cache_dir/_gh"
    [[ -f "$_gh_comp" ]] || gh completion -s zsh > "$_gh_comp"
    source "$_gh_comp"
  fi

  # chezmoi
  if (( $+commands[chezmoi] )); then
    local _chezmoi_comp="$cache_dir/_chezmoi"
    [[ -f "$_chezmoi_comp" ]] || chezmoi completion zsh > "$_chezmoi_comp"
    source "$_chezmoi_comp"
  fi

  # just
  if (( $+commands[just] )); then
    local _just_comp="$cache_dir/_just"
    [[ -f "$_just_comp" ]] || just --completions zsh > "$_just_comp"
    source "$_just_comp"
  fi

  # mise
  if (( $+commands[mise] )); then
    local _mise_comp="$cache_dir/_mise"
    [[ -f "$_mise_comp" ]] || mise completion zsh > "$_mise_comp"
    source "$_mise_comp"
  fi

  # pnpm
  if (( $+commands[pnpm] )); then
    local _pnpm_comp="$cache_dir/_pnpm"
    [[ -f "$_pnpm_comp" ]] || pnpm completion zsh > "$_pnpm_comp"
    source "$_pnpm_comp"
  fi

  # kubectl
  if (( $+commands[kubectl] )); then
    local _kubectl_comp="$cache_dir/_kubectl"
    [[ -f "$_kubectl_comp" ]] || kubectl completion zsh > "$_kubectl_comp"
    source "$_kubectl_comp"
    compdef k=kubectl
  fi
}

zinit wait"1" lucid light-mode for \
  atload"_zinit_setup_completions" \
    zdharma-continuum/null

unset _zsh_cache _completions_cache
