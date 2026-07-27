# plugins.zsh — zinit + zsh plugins (turbo mode), zoxide
# Provides:     zinit, p10k prompt, fast-syntax-highlighting,
#               zsh-autosuggestions, zsh-history-substring-search,
#               zsh-abbr (abbreviations), zoxide (z command)
# Requires:     git (for zinit clone)
# Side-effects: set ZINIT_HOME, zinit clone (first run only), load plugins,
#               call compinit, register many widgets
# Load-order:   AFTER perf-flags; provides zinit consumed by options.zsh and features/

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
  atload"autoload -Uz compinit && compinit -C -d \${XDG_CACHE_HOME:-\$HOME/.cache}/zsh/.zcompdump && zicdreplay" \
    zsh-users/zsh-completions

zinit wait lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting

zinit wait lucid light-mode for \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search

_zinit_setup_abbr() {
  # Session abbreviations: expand on Enter, full command saved in history
  # Editor
  abbr -S -qq v='nvim'
  abbr -S -qq vi='nvim'
  abbr -S -qq vim='nvim'

  # Tools
  abbr -S -qq lg='lazygit'
  abbr -S -qq k='kubectl'

  # Git
  abbr -S -qq g='git'
  abbr -S -qq ga='git add'
  abbr -S -qq gaa='git add --all'
  abbr -S -qq gb='git branch'
  abbr -S -qq gc='git commit'
  abbr -S -qq gcm='git commit -m'
  abbr -S -qq gco='git checkout'
  abbr -S -qq gcb='git checkout -b'
  abbr -S -qq gd='git diff'
  abbr -S -qq gds='git diff --staged'
  abbr -S -qq gf='git fetch'
  abbr -S -qq gl='git log --oneline -20'
  abbr -S -qq gp='git push'
  abbr -S -qq gpl='git pull'

  abbr -S -qq gst='git status'
  abbr -S -qq gsw='git switch'
  abbr -S -qq gswc='git switch -c'

  # Quick access for local config
  abbr -S -qq le='local-env edit'
  abbr -S -qq lz='local-zsh edit'
}

zinit wait lucid light-mode for \
  atload"_zinit_setup_abbr" \
    olets/zsh-abbr

# =============================================================================
# Powerlevel10k prompt
# =============================================================================
# depth=1: shallow clone for speed
# nocompile: p10k handles its own compilation, avoid zinit hook conflict
zinit ice depth=1 nocompile
zinit light romkatv/powerlevel10k

# =============================================================================
# Tool initialization (turbo mode)
# =============================================================================

# zoxide (turbo)
_zinit_setup_zoxide() {
  if (( $+commands[zoxide] )); then
    local _zoxide_cache="$ZSH_INIT_CACHE/zoxide.zsh"
    if _zsh_command_cache_prepare \
      "$_zoxide_cache" \
      "zoxide-init-v1" \
      zoxide \
      init zsh; then
      source "$_zoxide_cache"
    fi
  fi
}

zinit wait"1" lucid light-mode for \
  atload"_zinit_setup_zoxide" \
    zdharma-continuum/null

# atuin (turbo) - shell history (load after fzf to override Ctrl+R)
_zinit_setup_atuin() {
  if (( $+commands[atuin] )); then
    local _atuin_cache="$ZSH_INIT_CACHE/atuin.zsh"
    if _zsh_command_cache_prepare \
      "$_atuin_cache" \
      "atuin-init-v1" \
      atuin \
      init zsh --disable-up-arrow; then
      source "$_atuin_cache"
    fi
  fi
}

zinit wait"2" lucid light-mode for \
  atload"_zinit_setup_atuin" \
    zdharma-continuum/null

# fzf (turbo)
_zinit_setup_fzf() {
  if (( $+commands[fzf] )); then
    local _fzf_cache="$ZSH_INIT_CACHE/fzf.zsh"
    if _zsh_command_cache_prepare \
      "$_fzf_cache" \
      "fzf-shell-v1" \
      fzf \
      --zsh; then
      source "$_fzf_cache"
    fi

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
    local _direnv_cache="$ZSH_INIT_CACHE/direnv.zsh"
    if _zsh_command_cache_prepare \
      "$_direnv_cache" \
      "direnv-hook-v1" \
      direnv \
      hook zsh; then
      source "$_direnv_cache"
    fi
  fi
}

zinit wait"2" lucid light-mode for \
  atload"_zinit_setup_direnv" \
    zdharma-continuum/null

# =============================================================================
# Tool completions (cached, turbo mode)
# =============================================================================

_zinit_setup_completions() {
  local cache_dir="${XDG_CACHE_HOME}/zsh/completions"

  # gh (GitHub CLI)
  if (( $+commands[gh] )); then
    local _gh_comp="$cache_dir/_gh"
    if _zsh_command_cache_prepare \
      "$_gh_comp" \
      "gh-completion-v1" \
      gh \
      completion -s zsh; then
      source "$_gh_comp"
    fi
  fi

  # chezmoi
  if (( $+commands[chezmoi] )); then
    local _chezmoi_comp="$cache_dir/_chezmoi"
    if _zsh_command_cache_prepare \
      "$_chezmoi_comp" \
      "chezmoi-completion-v1" \
      chezmoi \
      completion zsh; then
      source "$_chezmoi_comp"
    fi
  fi

  # just
  if (( $+commands[just] )); then
    local _just_comp="$cache_dir/_just"
    if _zsh_command_cache_prepare \
      "$_just_comp" \
      "just-completion-v1" \
      just \
      --completions zsh; then
      source "$_just_comp"
    fi
  fi

  # herdr
  if (( $+commands[herdr] )); then
    local _herdr_comp="$cache_dir/_herdr"
    if _zsh_command_cache_prepare \
      "$_herdr_comp" \
      "herdr-completion-v1" \
      herdr \
      completion zsh; then
      source "$_herdr_comp"
    fi
  fi

  # mise
  if (( $+commands[mise] )); then
    local _mise_comp="$cache_dir/_mise"
    if _zsh_command_cache_prepare \
      "$_mise_comp" \
      "mise-completion-v1" \
      mise \
      completion zsh; then
      source "$_mise_comp"
    fi
  fi

  # pnpm
  if (( $+commands[pnpm] )); then
    local _pnpm_comp="$cache_dir/_pnpm"
    if _zsh_command_cache_prepare \
      "$_pnpm_comp" \
      "pnpm-completion-v1" \
      pnpm \
      completion zsh; then
      source "$_pnpm_comp"
    fi
  fi

  # moon (MoonBit)
  if (( $+commands[moon] )); then
    local _moon_comp="$cache_dir/_moon"
    if _zsh_command_cache_prepare \
      "$_moon_comp" \
      "moon-completion-v1" \
      moon \
      shell-completion --shell zsh; then
      source "$_moon_comp"
    fi
  fi

  # kubectl
  if (( $+commands[kubectl] )); then
    local _kubectl_comp="$cache_dir/_kubectl"
    if _zsh_command_cache_prepare \
      "$_kubectl_comp" \
      "kubectl-completion-v1" \
      kubectl \
      completion zsh; then
      source "$_kubectl_comp"
      compdef k=kubectl
    fi
  fi
}

zinit wait"1" lucid light-mode for \
  atload"_zinit_setup_completions" \
    zdharma-continuum/null
