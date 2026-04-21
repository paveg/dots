#!/bin/bash
# Install mermaid-ascii for Claude Code Stop hook rendering.
# Binary lands in $GOPATH/bin (default $HOME/go/bin), used by
# ~/.claude/hooks/mermaid-render.sh to turn fenced ```mermaid blocks
# into ASCII art after each assistant response.
#
# Triggered on chezmoi apply when this script changes.

set -euo pipefail

if ! command -v go >/dev/null 2>&1; then
  echo "go not found — skipping mermaid-ascii install" >&2
  exit 0
fi

echo "Installing mermaid-ascii via go install..."
go install github.com/AlexanderGrooff/mermaid-ascii@latest
