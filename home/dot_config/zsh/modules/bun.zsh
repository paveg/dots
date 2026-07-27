# bun.zsh — bun completions
# Provides:     _bun (completion function)
# Requires:     ~/.bun/_bun (optional — no-op if absent)
# Side-effects: call 'compinit -C' and source _bun
# Load-order:   AFTER plugins (use -C to skip recompile and avoid conflict with zinit's compinit)

# bun completions
# Pre-load compinit with -C so _bun's internal fallback (which calls plain
# `compinit`, triggering compaudit ~13ms) is skipped via its `command -v` guard.
if [[ -s "$HOME/.bun/_bun" ]]; then
  (( $+functions[compdef] )) || { autoload -Uz compinit && compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump" }
  source "$HOME/.bun/_bun"
fi
