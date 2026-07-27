#!/bin/bash
# Install or upgrade MoonBit toolchain
# Triggered on chezmoi apply when this script changes

set -euo pipefail

MOON_BIN="$HOME/.moon/bin/moon"

if [[ -x "$MOON_BIN" ]]; then
  echo "MoonBit already installed, upgrading..."
  "$MOON_BIN" upgrade 2>&1 || echo "moon upgrade failed (may already be latest)"
else
  echo "Installing MoonBit toolchain..."
  curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
fi

echo "MoonBit: $("$MOON_BIN" version 2>/dev/null || echo 'installation pending')"
