# pnpm.zsh — pnpm PATH setup
# Provides:     PNPM_HOME, PATH (pnpm bin)
# Requires:     none
# Side-effects: export PNPM_HOME and prepend it to PATH (with dedup check)
# Load-order:   free

# pnpm setup
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
