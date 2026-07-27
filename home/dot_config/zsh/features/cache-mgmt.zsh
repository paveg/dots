# cache-mgmt.zsh - clear/regenerate zsh init caches and benchmark startup
# Provides:     zsh-clear-cache, zsh-update-cache, zsh-bench
zsh-clear-cache() {
  rm -rf "$ZSH_INIT_CACHE"
  rm -rf "${XDG_CACHE_HOME}/zsh/completions"
  rm -rf "${XDG_CACHE_HOME}/p10k"*
  rm -rf "${XDG_CACHE_HOME}/gitstatus"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv.zsh"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv-pure.zsh"
  rm -rf "${XDG_DATA_HOME}/zinit"
  echo "All cache cleared. Restart shell to reinstall zinit."
  echo "Note: atuin history is preserved in ~/.local/share/atuin/"
}

zsh-update-cache() {
  rm -rf "$ZSH_INIT_CACHE"
  rm -rf "${XDG_CACHE_HOME}/zsh/completions"
  rm -rf "${XDG_CACHE_HOME}/p10k"*
  rm -rf "${XDG_CACHE_HOME}/gitstatus"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv.zsh"
  rm -f "${XDG_CACHE_HOME}/devbox/shellenv-pure.zsh"
  echo "Init cache cleared. Restart shell to regenerate."
}

zsh-bench() {
  for i in {1..10}; do
    time zsh -i -c exit
  done
}
