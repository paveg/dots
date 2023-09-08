IsExistCmd() { command -v "$1" > /dev/null 2>&1; }

# agkozak/zsh-z
alias j="z"

# Git / hub https://github.com/mislav/hub
IsExistCmd hub && eval "$(hub alias -s)"
alias g="hub"
alias ga="git add"
alias gs="git status"
alias gl="git log --oneline"
alias gc="git commit"
alias gp="git pull"
alias gb="git branch"
alias gd="git diff"
alias gr="git reset"
alias grb="git rebase"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gpu="git push"
alias gsu="git submodule update --remote --recursive --recommend-shallow --depth 1 -f"

# ls / eza https://github.com/eza-community/eza
IsExistCmd eza && alias ls="eza"
alias ll="ls -l"
alias la="ls -a"

# cat / bat https://github.com/sharkdp/bat
IsExistCmd bat && alias cat="bat -p"

# rg https://github.com/BurntSushi/ripgrep
alias rg="rg --hidden"

# [Disabled] thefuck https://github.com/nvbn/thefuck
# IsExistCmd thefuck && eval $(thefuck --alias)
