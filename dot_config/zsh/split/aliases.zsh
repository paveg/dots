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
alias lg='lazygit'
alias k='kubectl'

# Git shortcuts (with completion support)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git log --oneline -20'
alias gp='git push'
alias gpl='git pull'
alias gs='git status -sb'
alias gst='git status'
alias gsw='git switch'
alias gswc='git switch -c'

# Safe defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Quick aliases for local config
alias le='local-env edit'
alias lz='local-zsh edit'
