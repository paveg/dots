#!/bin/bash
# Setup GitHub CLI authentication using 1Password

set -euo pipefail

# Skip if op CLI is not available
if ! command -v op &>/dev/null; then
  echo "op CLI not found, skipping gh auth setup"
  exit 0
fi

# Skip if gh CLI is not available
if ! command -v gh &>/dev/null; then
  echo "gh CLI not found, skipping gh auth setup"
  exit 0
fi

# Skip if already authenticated
if gh auth status &>/dev/null; then
  echo "gh is already authenticated, skipping"
  exit 0
fi

echo "Setting up gh authentication via 1Password..."
op read "op://GH Token/token" | gh auth login --with-token

echo "gh authentication complete"
