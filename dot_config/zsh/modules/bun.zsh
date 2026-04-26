# bun completions
# Pre-load compinit with -C so _bun's internal fallback (which calls plain
# `compinit`, triggering compaudit ~13ms) is skipped via its `command -v` guard.
if [[ -s "$HOME/.bun/_bun" ]]; then
  autoload -Uz compinit && compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
  source "$HOME/.bun/_bun"
fi
