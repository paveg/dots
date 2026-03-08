# =============================================================================
# Aliases (command substitutions & safe defaults)
# =============================================================================
# Abbreviations (git shortcuts, tool shortcuts) are in abbreviations.zsh
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'

# Safe defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
