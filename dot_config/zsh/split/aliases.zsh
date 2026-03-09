# =============================================================================
# Aliases (command substitutions & safe defaults)
# =============================================================================
# Abbreviations (git shortcuts, tool shortcuts) are in abbreviations.zsh
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'

# Git: alias instead of abbr to override /usr/bin/gs (Ghostscript)
# abbr is turbo-loaded and may lose the race against PATH lookup
alias gs='git status -sb'

# Safe defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
