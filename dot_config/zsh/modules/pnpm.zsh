# pnpm.zsh — pnpm PATH setup
# Provides:     PNPM_HOME, PATH (pnpm bin)
# Requires:     なし
# Side-effects: PNPM_HOME export, PATH 先頭に追加 (重複防止チェックあり)
# Load-order:   free

# pnpm setup
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
