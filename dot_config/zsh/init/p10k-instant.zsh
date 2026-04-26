# p10k-instant.zsh — Powerlevel10k instant prompt loader
# Provides:     なし (p10k 内部状態を初期化)
# Requires:     ${XDG_CACHE_HOME}/p10k-instant-prompt-${USER}.zsh (初回起動時は不在で no-op)
# Side-effects: p10k instant prompt の cache を source
# Load-order:   AFTER auto-tmux, BEFORE plugins

# Powerlevel10k instant prompt
# Enable instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
