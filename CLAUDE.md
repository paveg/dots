# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [devbox](https://www.jetify.com/devbox). `.chezmoiroot` selects `home/` as the chezmoi source root. Inside it, files prefixed with `dot_` become dotfiles, and `private_` sets mode `0600` (e.g., `home/private_dot_zshrc.tmpl` → `~/.zshrc`).

Only files under `home/` are deployment sources. Repository files such as docs, tests, CI helpers, and the project-scoped `.claude/` stay outside that boundary and must not be added to `home/`. `home/.chezmoiignore` is reserved for target/profile/OS/runtime exclusions, not repository housekeeping.

## Commands

```bash
just test        # All checks: lint, profile rendering, format, hook & skill-script tests
just fmt         # Format Lua and Markdown files
just fmt-check   # Check formatting without changes
just lint        # Check zsh and lua syntax
just apply       # Apply dotfiles via chezmoi
just diff        # Show pending chezmoi changes
```

## Architecture

- **chezmoi templates** (`.tmpl` files): Use Go template syntax `{{ .variable }}` for conditional content
- **`home/dot_local/share/devbox/global/default/devbox.json.tmpl`**: Defines CLI tools installed via devbox global
- **justfile**: Task runner for formatting, linting, and chezmoi operations

### Key Data Variables (defined in `home/.chezmoi.yaml.tmpl`)

| Variable                         | Description                                    |
| -------------------------------- | ---------------------------------------------- |
| `.business_use`                  | `true` if `BUSINESS_USE=1` was set during init |
| `.osid`                          | OS identifier (e.g., `darwin`, `linux-ubuntu`) |
| `.name`, `.email`, `.work_email` | User info prompted on first run                |

### Template Testing

`chezmoi execute-template < file.tmpl` renders against the current config and touches nothing — reach for it first.

`chezmoi init` rewrites the real `~/.config/chezmoi/chezmoi.yaml` **even with `--dry-run`**. Never run it against the real config (especially with `BUSINESS_USE=1`, or from a shell that inherited it) — once flipped, the applied `~/.zshenv` exports `BUSINESS_USE=1` and re-poisons every later shell, including new `chezmoi init` runs. Isolate test inits:

```bash
tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/chezmoi"
printf 'data:\n  name: "Test"\n  email: "t@example.com"\n  work_email: "t@work.example.com"\n' > "$tmpdir/chezmoi/chezmoi.yaml"
XDG_CONFIG_HOME="$tmpdir" BUSINESS_USE=1 chezmoi init --source=. --dry-run        # business mode
XDG_CONFIG_HOME="$tmpdir" env -u BUSINESS_USE chezmoi init --source=. --dry-run   # personal mode
```

Recovery: `env -u BUSINESS_USE chezmoi init --source ~/.local/share/chezmoi && env -u BUSINESS_USE chezmoi apply`, then kill the tmux server and restart shells (inherited env survives `exec $SHELL -l`).

The Bash tool initializes from the user's profile, so its environment is never assumed clean — check `BUSINESS_USE` before any chezmoi operation rather than trusting the command line.

## Package Management Policy

CLI tools follow an availability waterfall — use the first layer that provides the package:

1. **devbox (Nix)** — first choice for cross-platform CLI tools. Most manifest entries intentionally use rolling `@latest`; `devbox.lock` is untracked because the chezmoi template renders different personal and business manifests. Add via `devbox global add`. Because `devbox.json` is a template, the change is **not** auto-persisted — the `devbox()` wrapper warns you to update `devbox.json.tmpl` by hand (personal packages go in the `not .business_use` block).
2. **mise** — Nix gap-filler only. Use when a tool is **not in nixpkgs** but available via a mise backend (`ubi:` release binaries, `go:`, `cargo:`, `npm:`). Declared in `home/dot_config/mise/config.toml`. mise does **not** manage language runtimes here — `node`/`go`/`deno` stay in devbox global.
3. **Homebrew** — last resort for CLI. Use only when a tool is in neither nix nor a mise backend (e.g. brew-tap-only tools).

Out of the waterfall (always Homebrew): GUI apps (`cask`), Mac App Store (`mas`), VSCode extensions, and macOS-specific CLI that isn't portable (e.g. `vips`, `swiftlint`, `xcodegen`).

After source changes, refresh with `chezmoi apply` followed by `devbox global install`, then inspect `devbox global list` for resolved-version changes. `brewbundle` refuses exact-name CLI overlaps from `brew`, `cargo`, `go`, `npm`, and `uv` with the authoritative rendered Devbox profile before replacing a tracked Brewfile. Go module paths are compared by their final component. Known providers are normalized (`git-delta` to `delta`). Runtime-bundled CLIs are not treated as duplicates: every Node distribution ships `corepack`, so `brew bundle dump` reports it wherever Node exists and it says nothing about who owns the runtime. It cannot detect other aliases or packages with different names, so review every dump manually.

## Authoring rules & skills

Rules (`home/dot_claude/rules/`) and skills (`home/dot_claude/skills/`) added to this repo are written in **English**. Japanese is allowed only where nuance requires it — e.g. a skill `description`'s trigger phrases that the user types in Japanese, or a generated-output template whose reader is Japanese.

Project-scoped rules live in repo-root `.claude/rules/` (`paths:`-scoped). The whole `.claude/` directory is gitignored, so a new file there needs `git add -f` — a plain `git add` silently does nothing.
