# p10k-instant.zsh — Powerlevel10k instant prompt loader
# Provides:     none (initializes p10k internal state)
# Requires:     ${XDG_CACHE_HOME}/p10k-instant-prompt-${USER}.zsh (no-op when absent on first run)
# Side-effects: source the p10k instant prompt cache
# Load-order:   AFTER auto-tmux, BEFORE plugins

# Powerlevel10k instant prompt
# Enable instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
