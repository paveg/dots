# cf-cli.zsh — CF CLI completions (shipped via Vite+)
# Provides:     _cf (completion)
# Requires:     ~/.config/cf/completions/_cf.zsh (任意 — 不在時は no-op)
# Side-effects: source completion file
# Load-order:   AFTER vite-plus

# CF CLI completions (shipped via Vite+)
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"
