#!/bin/bash

# @see https://wiki.archlinux.jp/index.php/XDG_Base_Directory
export XDG_CONFIG_HOME=$HOME/.config
export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship.toml

dotpath=$(ghq root)/github.com/paveg/dots
gitpath=$XDG_CONFIG_HOME/git

# shellcheck source=/dev/null
source "$ZMODPATH/util.zsh"

# zsh
if [ ! -f "$HOME/.zshenv" ]; then
	ln -sf "$dotpath/.zshenv" "$HOME/.zshenv"
	log_pass "Initialized $HOME/.zshenv"
fi
if [[ ! -d "$ZDOTDIR" ]]; then
	mkdir -p "$ZDOTDIR"
	ln -sf "$dotpath/zsh.d/.zshrc" "$ZDOTDIR/.zshrc"
	ln -sf "$dotpath/zsh.d/.zprofile" "$ZDOTDIR/.zprofile"
	ln -sf "$dotpath/zsh.d/.zshenv" "$ZDOTDIR/.zshenv"
fi
log_pass "Initialization zsh successfully!"

# starship
if [[ ! -f $STARSHIP_CONFIG ]]; then
	ln -sf "$dotpath/starship.toml" "$STARSHIP_CONFIG"
fi

# git
if [[ ! -d $gitpath ]]; then
	mkdir -p "$gitpath"
	log_pass "Created $gitpath"
fi
# shellcheck source=/dev/null
source ./git/symlink.sh

log_pass "Completed initializing dots 🎉"
