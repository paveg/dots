# dots

[![Test Dotfiles](https://github.com/paveg/dots/actions/workflows/test.yml/badge.svg)](https://github.com/paveg/dots/actions/workflows/test.yml)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [devbox](https://www.jetify.com/devbox).

## Quick Start

### New Machine Setup

```bash
# Install devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Install chezmoi via devbox
devbox global add chezmoi

# Apply dotfiles (you'll be prompted for name and email)
chezmoi init --apply paveg/dots

# For work environment (also prompts for work email)
BUSINESS_USE=1 chezmoi init --apply paveg/dots
```

On first run, you'll be prompted for:
- Your name
- Your email (personal)
- Your work email (only if `BUSINESS_USE=1`)

These values are stored in `~/.config/chezmoi/chezmoi.yaml`.

### Install Development Tools

```bash
# Install all CLI tools via devbox global
devbox global add neovim git tmux ghq fzf ripgrep fd bat eza zoxide starship lazygit direnv jq yq delta
```

## Structure

```
dots/
├── .chezmoi.yaml.tmpl      # chezmoi config (OS, BUSINESS_USE detection)
├── .chezmoiignore          # OS-specific ignores
├── devbox.json             # Global CLI tools
├── dot_zshenv.tmpl         # -> ~/.zshenv
├── dot_zshrc.tmpl          # -> ~/.zshrc
└── dot_config/
    ├── git/
    │   ├── config          # -> ~/.config/git/config (conditional includes)
    │   ├── main.tmpl       # -> ~/.config/git/main
    │   ├── ignore          # -> ~/.config/git/ignore
    │   └── freee.tmpl      # -> ~/.config/git/freee (work only)
    ├── nvim/               # -> ~/.config/nvim/
    │   ├── init.lua
    │   └── lua/plugins/
    │       ├── colorscheme.lua
    │       ├── ui.lua
    │       ├── editor.lua
    │       ├── treesitter.lua
    │       ├── lsp.lua
    │       ├── completion.lua
    │       └── copilot.lua
    ├── starship.toml       # -> ~/.config/starship.toml
    ├── lazygit/config.yml  # -> ~/.config/lazygit/config.yml
    └── ghostty/config      # -> ~/.config/ghostty/config
```

## Tools (via devbox)

| Tool | Description |
|------|-------------|
| neovim | Editor |
| tmux | Terminal multiplexer |
| ghq | Repository management |
| fzf | Fuzzy finder |
| ripgrep | Fast grep |
| fd | Fast find |
| bat | Better cat |
| eza | Better ls |
| zoxide | Smart cd |
| starship | Cross-shell prompt |
| lazygit | Git TUI |
| direnv | Per-directory env vars |
| delta | Better git diff |

## Features

### Terminal: Ghostty
- Font: JetBrains Mono Nerd Font
- Theme: Catppuccin Mocha
- Native tabs/splits

### Shell: zsh + zinit turbo mode
- Fast startup (~50ms)
- Syntax highlighting
- Autosuggestions
- Auto tmux on Linux SSH

### Editor: Neovim (kickstart-based)
- LSP support (Mason)
- GitHub Copilot
- Telescope fuzzy finder
- Treesitter

## Keybindings

### Zsh

| Key | Description |
|-----|-------------|
| `Ctrl+g` | ghq + fzf (repository navigation) |
| `Ctrl+r` | History search (fzf) |
| `z <dir>` | Smart cd (zoxide) |

### Neovim (Leader = Space)

| Key | Description |
|-----|-------------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>e` | File explorer |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover documentation |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `gcc` | Toggle comment |
| `<leader>cc` | Copilot Chat |

### Lazygit

| Key | Description |
|-----|-------------|
| `C` | Conventional commit |

## Environment Variables

### Local Configuration (per-machine, not tracked by git)

| File | Purpose |
|------|---------|
| `~/.env.local` | Machine-specific environment variables |
| `~/.zshrc.local` | Machine-specific shell config (aliases, functions) |
| `.envrc` | Directory-specific env vars (via direnv) |

```bash
# ~/.env.local - environment variables
export GITHUB_TOKEN="xxx"
export AWS_PROFILE="my-profile"

# ~/.zshrc.local - shell customizations
alias myalias='some-command'
export PATH="$HOME/custom/bin:$PATH"
```

### Work vs Personal

```bash
# Work environment
BUSINESS_USE=1 chezmoi init --apply paveg/dots

# Personal (default)
chezmoi init --apply paveg/dots
```

### Directory-specific (direnv)

```bash
# Create .envrc in any project directory
echo 'export DATABASE_URL="postgres://..."' > .envrc
direnv allow
```

## Utility Functions

| Command | Description |
|---------|-------------|
| `dots` | **Show all dotfiles commands and keybindings** |
| `repos` | ghq + fzf repository navigation |
| `rub` | Remove merged git branches |
| `zsh-bench` | Benchmark shell startup |
| `zsh-clear-cache` | Clear all zsh caches |
| `zsh-update-cache` | Regenerate init caches |
| `local-env` | Manage ~/.env.local |
| `local-zsh` | Manage ~/.zshrc.local |
| `le` | Quick: edit ~/.env.local |
| `lz` | Quick: edit ~/.zshrc.local |

## Platform Support

- macOS (arm64/x86_64)
- Linux (desktop/server)

### SSH/Remote Server Setup

```bash
# On remote server
curl -fsSL https://get.jetify.com/devbox | bash
devbox global add chezmoi neovim tmux ghq fzf ripgrep fd bat eza zoxide starship lazygit direnv delta

chezmoi init --apply paveg/dots
```

**Note:** Ghostty config is automatically skipped on SSH sessions (detected via `$SSH_CLIENT`).

**Auto tmux:** On Linux SSH sessions, tmux starts automatically. Disable with:
```bash
export DISABLE_AUTO_TMUX=1
```

## Development

### Task Runner: just

```bash
# Show all commands
just

# Format all files
just fmt

# Check format (CI runs this)
just fmt-check

# Run linters
just lint

# Run all checks
just test
```

### Just Commands

| Command | Description |
|---------|-------------|
| `just` | Show available commands |
| `just fmt` | Format all files |
| `just fmt-check` | Check formatting |
| `just lint` | Run linters |
| `just test` | Run all checks |
| `just apply` | Apply dotfiles |
| `just diff` | Show pending changes |
| `just clean` | Clear all caches |

## License

MIT
