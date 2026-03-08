# =============================================================================
# History
# =============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY INC_APPEND_HISTORY

# =============================================================================
# Options
# =============================================================================
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP

# =============================================================================
# Key Bindings
# =============================================================================
bindkey -e

# Disable mouse reporting in the shell (prevents escape sequences on scroll)
# Deferred to precmd to avoid output during p10k instant prompt
autoload -Uz add-zsh-hook
_disable_mouse_reporting() {
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
  # Remove this hook after first run
  add-zsh-hook -d precmd _disable_mouse_reporting
}
add-zsh-hook precmd _disable_mouse_reporting

# =============================================================================
# Completion settings
# =============================================================================
zinit wait lucid light-mode for \
  atload'
    zstyle ":completion:*" menu select
    zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"
    zstyle ":completion:*" use-cache on
    zstyle ":completion:*" cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

  ' \
    zdharma-continuum/null
