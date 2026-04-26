# bun.zsh — bun completions
# Provides:     _bun (completion function)
# Requires:     ~/.bun/_bun (任意 — 不在時は no-op)
# Side-effects: compinit -C を呼んで _bun を source
# Load-order:   AFTER plugins (zinit の compinit と競合しないよう -C で skip)

# bun completions
# Pre-load compinit with -C so _bun's internal fallback (which calls plain
# `compinit`, triggering compaudit ~13ms) is skipped via its `command -v` guard.
if [[ -s "$HOME/.bun/_bun" ]]; then
  autoload -Uz compinit && compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
  source "$HOME/.bun/_bun"
fi
