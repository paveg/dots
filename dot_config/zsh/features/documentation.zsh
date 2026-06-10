# documentation.zsh - view the Neovim config README in the terminal
# Provides:     vdoc
# Requires:     glow
vdoc() {
  local readme="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/README.md"
  if [[ -f "$readme" ]]; then
    glow "$readme"
  else
    echo "README not found: $readme"
    echo "Run 'chezmoi apply' to install."
  fi
}
