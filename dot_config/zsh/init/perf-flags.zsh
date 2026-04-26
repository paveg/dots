# perf-flags.zsh — zsh startup performance flags
# Provides:     DISABLE_MAGIC_FUNCTIONS, skip_global_compinit
# Requires:     none
# Side-effects: set zsh global vars (affects zinit / oh-my-zsh behavior)
# Load-order:   BEFORE plugins (so zinit picks them up)

# Performance flags
DISABLE_MAGIC_FUNCTIONS=true
skip_global_compinit=1
