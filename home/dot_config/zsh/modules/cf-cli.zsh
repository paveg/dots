# cf-cli.zsh — CF CLI completions (shipped via Vite+)
# Provides:     _cf (completion)
# Requires:     ~/.config/cf/completions/_cf.zsh (optional — no-op if absent)
# Side-effects: source completion file
# Load-order:   AFTER vite-plus

# CF CLI completions (shipped via Vite+)
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"
