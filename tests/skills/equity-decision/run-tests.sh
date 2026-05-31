#!/usr/bin/env bash
# Test runner for dot_claude/skills/equity-decision/scripts/*.py
# Runs all pytest tests in this directory using `uv run`.
set -euo pipefail

cd "$(dirname "$0")"

uv run --with pytest --with requests-mock --with yfinance --with beautifulsoup4 --with lxml \
  python -m pytest -v --tb=short
