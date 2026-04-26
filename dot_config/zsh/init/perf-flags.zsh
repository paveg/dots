# perf-flags.zsh — zsh startup performance flags
# Provides:     DISABLE_MAGIC_FUNCTIONS, skip_global_compinit
# Requires:     なし
# Side-effects: zsh global vars を設定 (zinit / oh-my-zsh の挙動に影響)
# Load-order:   BEFORE plugins (zinit が読む前)

# Performance flags
DISABLE_MAGIC_FUNCTIONS=true
skip_global_compinit=1
