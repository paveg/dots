#!/bin/bash
# Configure atcoder-cli (acc) defaults after install.
# Template files live in ~/.config/atcoder-cli-nodejs/go/ (chezmoi-managed).
# Runs once per machine.

set -euo pipefail

if ! command -v acc >/dev/null 2>&1; then
  echo "acc not found — skipping acc config" >&2
  exit 0
fi

acc config default-template go
acc config default-task-choice all
