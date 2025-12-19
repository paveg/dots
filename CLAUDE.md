# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [devbox](https://www.jetify.com/devbox). Files prefixed with `dot_` become dotfiles (e.g., `dot_zshrc.tmpl` → `~/.zshrc`).

## Commands

```bash
just test        # Run all checks (lint + format)
just fmt         # Format all files (Lua, JSON)
just fmt-check   # Check formatting without changes
just lint        # Check zsh and lua syntax
just apply       # Apply dotfiles via chezmoi
just diff        # Show pending chezmoi changes
```

## Architecture

- **chezmoi templates** (`.tmpl` files): Use Go template syntax `{{ .variable }}` for conditional content
- **devbox.json**: Defines CLI tools installed via devbox global
- **justfile**: Task runner for formatting, linting, and chezmoi operations

### Key Data Variables (defined in `.chezmoi.yaml.tmpl`)

| Variable | Description |
|----------|-------------|
| `.business_use` | `true` if `BUSINESS_USE=1` was set during init |
| `.osid` | OS identifier (e.g., `darwin`, `linux-ubuntu`) |
| `.name`, `.email`, `.work_email` | User info prompted on first run |

### Configuration Directories

- `dot_config/nvim/` - Neovim config (kickstart-based, uses lazy.nvim)
- `dot_config/git/` - Git config with conditional includes for work/personal
- `dot_config/ghostty/` - Terminal emulator config
- `private_dot_ssh/` - SSH config (common settings only)

## CI

GitHub Actions runs on every push/PR to main:
- Format check (stylua for Lua, JSON validation)
- Lint (zsh syntax, lua syntax)
- Chezmoi dry-run on Linux and macOS (both personal and business modes)
- Neovim startup test
