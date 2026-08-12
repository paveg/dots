#!/bin/bash
# Install AtCoder CLI tooling:
#   - atcoder-cli (acc): npm pkg, installed via pnpm (no nix equivalent)
#   - online-judge-tools (oj): installed via uv with Selenium in the same
#     isolated env. AtCoder's login page has JS/captcha checks that oj's CUI
#     login cannot pass, so Selenium (browser-driven) is required. The nix
#     version cannot be augmented with Selenium, hence uv.
#
# Triggered on chezmoi apply when this script changes.

set -euo pipefail

# atcoder-cli via pnpm
if command -v acc >/dev/null 2>&1; then
  :
elif command -v pnpm >/dev/null 2>&1; then
  echo "Installing atcoder-cli via pnpm..."
  # This runs under bash, so modules/pnpm.zsh has not set PNPM_HOME here.
  export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
  export PATH="$PNPM_HOME/bin:$PATH"
  pnpm add -g atcoder-cli
else
  echo "pnpm not found — skipping acc install" >&2
fi

# online-judge-tools + selenium via uv
if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found — skipping oj install" >&2
  exit 0
fi

if uv tool list 2>/dev/null | grep -qE '^online-judge-tools\b'; then
  # Already installed; ensure selenium is present in its env
  uv tool install --with selenium --with setuptools --force online-judge-tools >/dev/null
else
  echo "Installing online-judge-tools with selenium via uv..."
  uv tool install --with selenium --with setuptools online-judge-tools
fi
