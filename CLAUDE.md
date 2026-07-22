# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [devbox](https://www.jetify.com/devbox). Files prefixed with `dot_` become dotfiles (e.g., `dot_zshrc.tmpl` → `~/.zshrc`).

Every file in this repo is a deployment source by default: a new repo-level file (docs, configs, CI helpers — anything meant for the repo, not for `$HOME`) needs a matching entry in `.chezmoiignore`, or the next `chezmoi apply` deploys it into `$HOME`. This applies to any nested CLAUDE.md too — and a deployed `~/.claude/rules/CLAUDE.md` would even load as an always-on global rule.

## Commands

```bash
just test        # All checks: lint, zsh header lint, format, hook & skill-script tests (CI runs only a subset)
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

| Variable                         | Description                                    |
| -------------------------------- | ---------------------------------------------- |
| `.business_use`                  | `true` if `BUSINESS_USE=1` was set during init |
| `.osid`                          | OS identifier (e.g., `darwin`, `linux-ubuntu`) |
| `.name`, `.email`, `.work_email` | User info prompted on first run                |

### Template Testing

`chezmoi init` rewrites the real `~/.config/chezmoi/chezmoi.yaml` **even with `--dry-run`**. Never run it against the real config (especially with `BUSINESS_USE=1`, or from a shell that inherited it) — once flipped, the applied `~/.zshenv` exports `BUSINESS_USE=1` and re-poisons every later shell, including new `chezmoi init` runs. Isolate test inits:

```bash
tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/chezmoi"
printf 'data:\n  name: "Test"\n  email: "t@example.com"\n  work_email: "t@work.example.com"\n' > "$tmpdir/chezmoi/chezmoi.yaml"
XDG_CONFIG_HOME="$tmpdir" BUSINESS_USE=1 chezmoi init --source=. --dry-run        # business mode
XDG_CONFIG_HOME="$tmpdir" env -u BUSINESS_USE chezmoi init --source=. --dry-run   # personal mode
```

Recovery: `env -u BUSINESS_USE chezmoi init --source ~/.local/share/chezmoi && env -u BUSINESS_USE chezmoi apply`, then kill the tmux server and restart shells (inherited env survives `exec $SHELL -l`).

## Package Management Policy

Personal (non-business) CLI tools follow an availability waterfall — use the first layer that provides the package:

1. **devbox (Nix)** — first choice for cross-platform CLI tools. Reproducible, pinned in `devbox.lock`. Add via `devbox global add`. Because `devbox.json` is a chezmoi template (business/personal split), the change is **not** auto-persisted — the `devbox()` wrapper warns you to add the package to the matching block in `devbox.json.tmpl` by hand (personal packages go in the `not .business_use` block).
2. **mise** — Nix gap-filler only. Use when a tool is **not in nixpkgs** but available via a mise backend (`ubi:` release binaries, `go:`, `cargo:`, `npm:`). Declared in `dot_config/mise/config.toml`. mise does **not** manage language runtimes here — `node`/`go`/`deno` stay in devbox global.
3. **Homebrew** — last resort for CLI. Use only when a tool is in neither nix nor a mise backend (e.g. brew-tap-only tools).

Out of the waterfall (always Homebrew): GUI apps (`cask`), Mac App Store (`mas`), VSCode extensions, and macOS-specific CLI that isn't portable (e.g. `colima`, `vips`, `swiftlint`, `xcodegen`).

## Authoring rules & skills

Rules (`dot_claude/rules/`) and skills (`dot_claude/skills/`) added to this repo are written in **English**. Japanese is allowed only where nuance requires it — e.g. a skill `description`'s trigger phrases that the user types in Japanese, or a generated-output template whose reader is Japanese.

Project-scoped rules live in repo-root `.claude/rules/` (`paths:`-scoped). The whole `.claude/` directory is gitignored, so a new file there needs `git add -f` — a plain `git add` silently does nothing.
