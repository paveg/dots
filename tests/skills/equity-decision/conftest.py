"""Shared fixtures for equity-decision fetcher tests."""
import sys
from pathlib import Path

import pytest

SCRIPTS_DIR = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))


@pytest.fixture
def us_tickers() -> list[str]:
    return ["NVDA", "AAPL"]


@pytest.fixture
def jp_tickers() -> list[str]:
    return ["7203", "9984"]
