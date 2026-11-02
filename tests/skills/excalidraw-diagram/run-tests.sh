#!/usr/bin/env bash
# Hermetic tests for the excalidraw-diagram renderer: input validation and the
# asset path guard. No browser, no network, no node_modules.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

if ! command -v node >/dev/null 2>&1; then
  echo "✗ node not found" >&2
  exit 1
fi

node --test guards.test.mjs
