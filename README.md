# dots

[![Test Dotfiles](https://github.com/paveg/dots/actions/workflows/test.yml/badge.svg)](https://github.com/paveg/dots/actions/workflows/test.yml)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [devbox](https://www.jetify.com/devbox).

## Quick Start

### New Machine Setup (One-liner)

```bash
# Personal
curl -fsSL https://raw.githubusercontent.com/paveg/dots/main/install.sh | bash

# Work environment
curl -fsSL https://raw.githubusercontent.com/paveg/dots/main/install.sh | BUSINESS_USE=1 bash
```

### Manual Setup

```bash
# Install devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Load devbox into current shell (required before using devbox commands)
eval "$(devbox global shellenv)"

# Install chezmoi via devbox
devbox global add chezmoi

# Reload to get chezmoi in PATH
eval "$(devbox global shellenv)"

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

### Install Font (for Ghostty)

```bash
# macOS
brew tap homebrew/cask-fonts
brew install --cask font-udev-gothic-nf
```

### Install Development Tools

```bash
# Apply dotfiles (includes devbox global config)
chezmoi apply

# Install all CLI tools via devbox global
devbox global install
```

## Structure

```
dots/
├── .chezmoiroot            # selects home/ as the deployment source
├── home/                   # only this subtree is managed by chezmoi
│   ├── .chezmoi.yaml.tmpl  # chezmoi config (OS, BUSINESS_USE detection)
│   ├── .chezmoiignore      # target/profile/OS/runtime exclusions
│   ├── dot_zshenv.tmpl     # -> ~/.zshenv
│   ├── dot_zshrc.tmpl      # -> ~/.zshrc
│   ├── dot_p10k.zsh        # -> ~/.p10k.zsh
│   ├── dot_claude/         # -> ~/.claude/
│   ├── dot_codex/          # -> ~/.codex/
│   ├── dot_local/
│   │   └── share/devbox/global/default/
│   │       └── devbox.json.tmpl
│   ├── private_dot_ssh/    # -> ~/.ssh/
│   └── dot_config/
│       ├── git/
│       ├── nvim/
│       ├── zsh/
│       ├── direnv/
│       ├── gitleaks/
│       ├── lazygit/
│       └── ghostty/
├── .github/                # CI; never deployed
├── docs/                   # ADRs and historical plans; never deployed
├── tests/                  # hook and skill tests; never deployed
├── justfile
└── install.sh
```

The `home/` boundary keeps repository-only files out of `$HOME` without adding
housekeeping entries to `home/.chezmoiignore`.

Historical ADRs and plans may use chezmoi-source-relative paths; from the
repository root, prepend `home/` to those paths in the current layout.

## Tools (via devbox)

The rendered global manifest always includes Go 1.25, Node.js 24, Neovim 0.11,
shell utilities, Git/GitHub tooling, Kubernetes tooling, formatters, and
linters. Personal-only tools include `gitleaks`, `protobuf`, `grpcurl`,
`cloudflared`, and `flyctl`; business-only tools include `aws-sso-util`,
`colima`, and the Docker CLI/tooling. The
[manifest template](home/dot_local/share/devbox/global/default/devbox.json.tmpl)
is the complete package list.

Most entries intentionally use rolling `@latest` versions. `devbox.lock` is
not tracked because one chezmoi template renders different personal and
business manifests. Refresh deliberately:

```bash
chezmoi apply
devbox global install
devbox global list  # review the resolved versions
```

Source changes do not alter the active manifest until `chezmoi apply` runs.
Review resolved-version changes before relying on the refreshed toolchain.

Homebrew owns GUI/host-specific exceptions. `brewbundle` dumps to a temporary
file and refuses to replace the tracked Brewfile when an exact CLI entry from
`brew`, `cargo`, `go`, `npm`, or `uv` is already owned by the authoritative
rendered Devbox profile. Go module paths use their final component for this
comparison. Known providers are normalized (`git-delta` to `delta`, `corepack`
to `nodejs`). Other aliases or differently named packages still require manual
review.

## Features

### Terminal: Ghostty

- Font: UDEV Gothic NF (Japanese-friendly Nerd Font)
- Theme: Catppuccin Mocha
- Native tabs/splits

#### Font Installation

The Ghostty terminal uses [UDEV Gothic NF](https://github.com/yuru7/udev-gothic), a programming font with Nerd Font icons and excellent Japanese support.

**macOS (Homebrew):**

```bash
brew tap homebrew/cask-fonts
brew install --cask font-udev-gothic-nf
```

**Linux (manual):**

```bash
# Download and install to user fonts directory
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/yuru7/udev-gothic/releases/download/v2.1.0/UDEVGothic_NF_v2.1.0.zip
unzip UDEVGothic_NF_v2.1.0.zip
fc-cache -fv
```

### Shell: zsh + zinit turbo mode

- Fast startup (~50ms) with powerlevel10k instant prompt
- Powerlevel10k prompt (Nerd Font icons, git status)
- Syntax highlighting
- Autosuggestions
- Auto tmux on Linux SSH

**Prompt customization:**

```bash
p10k configure  # Run the configuration wizard
```

### Editor: Neovim (kickstart-based)

- LSP support (Mason)
- GitHub Copilot
- Telescope fuzzy finder
- Treesitter

### Security: gitleaks

Prevents committing secrets (API keys, tokens, passwords, etc).

```bash
# Scan repository for secrets
gitleaks detect --source . --verbose

# Check staged files before commit
gitleaks protect --staged --verbose

# Scan git history
gitleaks detect --source . --verbose --log-opts="--all"
```

**Configuration:**

- Global config: `~/.config/gitleaks/config.toml` (auto-loaded via `$GITLEAKS_CONFIG`)
- Per-repo override: `.gitleaks.toml` in project root
- 800+ built-in patterns with common false-positive exclusions

## Keybindings

### Zsh

| Key       | Description                       |
| --------- | --------------------------------- |
| `Ctrl+g`  | ghq + fzf (repository navigation) |
| `Ctrl+r`  | History search (fzf)              |
| `z <dir>` | Smart cd (zoxide)                 |

### Neovim (Leader = Space)

| Key          | Description         |
| ------------ | ------------------- |
| `<leader>ff` | Find files          |
| `<leader>fg` | Live grep           |
| `<leader>fb` | Buffers             |
| `<leader>e`  | File explorer       |
| `gd`         | Go to definition    |
| `gr`         | Go to references    |
| `K`          | Hover documentation |
| `<leader>rn` | Rename              |
| `<leader>ca` | Code action         |
| `gcc`        | Toggle comment      |
| `<leader>cc` | Copilot Chat        |

### Lazygit

| Key | Description         |
| --- | ------------------- |
| `C` | Conventional commit |

## Environment Variables

### Local Configuration (per-machine, not tracked by git)

| File             | Purpose                                                         |
| ---------------- | --------------------------------------------------------------- |
| `~/.env.local`   | Machine-specific environment variables                          |
| `~/.zshrc.local` | Machine-specific shell config (aliases, functions)              |
| `.env`           | Data-only project variables, loaded after explicit direnv allow |
| `.envrc`         | Project environment logic, loaded after explicit direnv allow   |

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

Direnv 2.31 or newer discovers `.env` files directly. It parses them as dotenv
data rather than sourcing them as shell scripts, so command substitutions are
not executed. The first load requires explicit approval, and any content change
revokes that approval until it is reviewed and allowed again. Variables are
automatically unloaded when leaving the directory.

```bash
# Data-only variables need no .envrc boilerplate
printf '%s\n' 'DATABASE_URL=postgres://localhost/app' > .env
direnv allow  # review first; rerun after changing .env
```

For project logic, use an `.envrc`. Direnv's version-gated standard library
provides `dotenv_if_exists` and watches the loaded file. Allowing that `.envrc`
intentionally delegates trust to the `.env` it parses: later `.env` data
changes reload in the active shell without another `direnv allow`, while
`.envrc` changes still require re-approval. The nested `.env` remains dotenv
data and is never sourced as shell code.

```bash
printf '%s\n' 'dotenv_if_exists' > .envrc
direnv allow  # review first; rerun after changing .envrc
```

Prefer direct `.env` loading without an `.envrc` when every `.env` edit should
cross the strict per-file review and re-allow boundary.

## Utility Functions

| Command            | Description                                                                          |
| ------------------ | ------------------------------------------------------------------------------------ |
| `dots`             | **Show all dotfiles commands and keybindings**                                       |
| `repos`            | ghq + fzf repository navigation                                                      |
| `gcof`             | Switch git branch with fzf (local default, Ctrl-A/R filters, commit-history preview) |
| `rub`              | Remove merged git branches                                                           |
| `kctx`             | Switch Kubernetes context (fzf)                                                      |
| `kns`              | Switch Kubernetes namespace (fzf)                                                    |
| `kinfo`            | Show current context/namespace                                                       |
| `zsh-bench`        | Benchmark shell startup                                                              |
| `zsh-clear-cache`  | Clear all zsh caches                                                                 |
| `zsh-update-cache` | Regenerate init caches                                                               |
| `local-env`        | Manage ~/.env.local                                                                  |
| `local-zsh`        | Manage ~/.zshrc.local                                                                |
| `le`               | Quick: edit ~/.env.local                                                             |
| `lz`               | Quick: edit ~/.zshrc.local                                                           |

## Platform Support

- macOS (arm64/x86_64)
- Linux (desktop/server)

### SSH/Remote Server Setup

```bash
# One-liner
curl -fsSL https://raw.githubusercontent.com/paveg/dots/main/install.sh | bash

# Then install tools (devbox global config is already applied by chezmoi)
eval "$(devbox global shellenv)"
devbox global install
```

**Note:** Ghostty config is automatically skipped on SSH sessions (detected via `$SSH_CLIENT`).

**Auto tmux:** On Linux SSH sessions, tmux starts automatically. Disable with:

```bash
export DISABLE_AUTO_TMUX=1
```

### SSH Config

Common SSH settings are managed, host-specific configs should be in `~/.ssh/config.local`:

```bash
# ~/.ssh/config.local (not tracked, create manually)
Host github.com
  IdentityFile ~/.ssh/id_ed25519

Host myserver
  HostName 192.168.1.100
  User myuser
  IdentityFile ~/.ssh/id_ed25519
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

| Command          | Description             |
| ---------------- | ----------------------- |
| `just`           | Show available commands |
| `just fmt`       | Format all files        |
| `just fmt-check` | Check formatting        |
| `just lint`      | Run linters             |
| `just test`      | Run all checks          |
| `just apply`     | Apply dotfiles          |
| `just diff`      | Show pending changes    |
| `just clean`     | Clear all caches        |

## License

MIT
