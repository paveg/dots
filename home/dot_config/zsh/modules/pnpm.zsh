# pnpm.zsh — pnpm PATH setup
# Provides:     PNPM_HOME, PATH (pnpm bin)
# Requires:     none
# Side-effects: export PNPM_HOME and prepend it to PATH (with dedup check)
# Load-order:   free

# pnpm installs global binaries into $PNPM_HOME/bin, not $PNPM_HOME itself,
# and refuses `pnpm add -g` outright when that directory is absent from PATH.
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
