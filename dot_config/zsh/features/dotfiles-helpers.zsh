dots() {
  cat << 'EOF'
╭──────────────────────────────────────────────────────────────────╮
│                         dots - dotfiles                          │
╰──────────────────────────────────────────────────────────────────╯

📁 Config Locations
  ~/.config/nvim/      Neovim (kickstart + Copilot)
  ~/.config/git/       Git (delta, conditional includes)
  ~/.p10k.zsh              Prompt (powerlevel10k)
  ~/.config/lazygit/   Git TUI (conventional commits)
  ~/.config/ghostty/   Terminal (Catppuccin Mocha, OSC 52)
  ~/.config/atuin/     Shell history (fuzzy search)
  ~/.tmux.conf         Tmux (Catppuccin, vim keys, OSC 52)

🔧 Local Config (per-machine, not tracked)
  ~/.env.local         Global environment variables
  ~/.zshrc.local       Shell customizations
  .envrc               Per-project env (direnv, needs allow)
  .env                  Per-project env (auto-loaded)

⌨️  Key Bindings
  Ctrl+g       Repository navigation (ghq + fzf)
  Ctrl+t       File search with preview (fzf)
  Ctrl+r       History search (atuin)
  Alt+c        Directory navigation (fzf)
  Alt+r        Live grep -> nvim (rg + fzf)
  Ctrl+u/d     Scroll preview (fzf/atuin)
  z <dir>      Smart cd (zoxide)

🖥️  Tmux (Prefix = Ctrl+a)
  prefix + |   Split horizontal
  prefix + -   Split vertical
  prefix + h/j/k/l   Navigate panes
  prefix + r   Reload config
  v            Begin selection (copy mode)
  y            Copy to clipboard (OSC 52)
  Shift+drag   Copy via terminal (bypass tmux)

🛠️  Commands
  repos        Jump to repository (ghq + fzf)
  rgn          Live grep -> open in nvim (rg + fzf, Tab: multi-select)
  rub          Remove merged git branches
  lg           lazygit
  kctx         Switch kube context (fzf)
  kns          Switch namespace (fzf)
  kinfo        Show current context/namespace

  le           Edit ~/.env.local
  lz           Edit ~/.zshrc.local
  local-env    Manage environment variables
  local-zsh    Manage shell config

  zsh-bench    Benchmark shell startup
  zsh-clear-cache   Clear all caches
  zsh-update-cache  Regenerate init caches

📝 Neovim (Leader = Space)
  <leader>ff   Find files
  <leader>fg   Live grep
  <leader>e    File explorer
  gd           Go to definition
  <leader>cc   Copilot Chat

🔄 Chezmoi
  chezmoi diff       Show pending changes
  chezmoi apply      Apply changes
  chezmoi edit       Edit source files
  chezmoi update     Pull & apply latest

📦 Devbox
  devbox global list   List installed tools
  devbox global add    Install tool globally

EOF
}
