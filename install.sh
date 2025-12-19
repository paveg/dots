#!/bin/bash
# Bootstrap script for paveg/dots
# Usage: curl -fsSL https://raw.githubusercontent.com/paveg/dots/main/install.sh | bash
# With work environment: curl -fsSL ... | BUSINESS_USE=1 bash

set -e

echo "==> Installing dotfiles..."

# Install Nix if not present (required by devbox)
if ! command -v nix &> /dev/null; then
  echo "==> Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  # Source nix for current session
  if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
fi

# Install devbox if not present
if ! command -v devbox &> /dev/null; then
  echo "==> Installing devbox..."
  curl -fsSL https://get.jetify.com/devbox | bash -s -- -f
fi

# Set up devbox shellenv (only if nix is available)
if command -v nix &> /dev/null; then
  eval "$(devbox global shellenv 2>/dev/null || true)"
fi

# Install chezmoi via devbox if not present
if ! command -v chezmoi &> /dev/null; then
  echo "==> Installing chezmoi via devbox..."
  devbox global add chezmoi
  eval "$(devbox global shellenv)"
fi

# Apply dotfiles
echo "==> Applying dotfiles..."
if [[ -n "$BUSINESS_USE" ]]; then
  BUSINESS_USE=1 chezmoi init --apply paveg/dots
else
  chezmoi init --apply paveg/dots
fi

echo "==> Done! Restart your shell or run: exec zsh"
