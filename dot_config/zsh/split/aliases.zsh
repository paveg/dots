# =============================================================================
# Aliases
# =============================================================================
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias g='git'
alias lg='lazygit'
alias k='kubectl'

# Git shortcuts
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gf='git fetch'
alias gp='git pull'
alias gs='git status'

# Safe defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Quick aliases for local config
alias le='local-env edit'
alias lz='local-zsh edit'
