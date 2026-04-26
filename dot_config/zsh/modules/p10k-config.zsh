# p10k-config.zsh — Powerlevel10k user config loader
# Provides:     なし (~/.p10k.zsh が prompt を構成)
# Requires:     ~/.p10k.zsh (任意 — `p10k configure` で生成、不在時は no-op)
# Side-effects: source ~/.p10k.zsh
# Load-order:   LAST (全プラグイン load 後、prompt が表示される直前)

# Powerlevel10k configuration
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
