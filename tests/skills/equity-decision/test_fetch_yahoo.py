"""Tests for scripts/fetch_yahoo.py.

The script's contract:
- argv[1] is the ticker (US: AAPL; JP: 7203 — auto-suffixed .T inside the script)
- prints JSON to stdout with shape: {ticker, market, price, summary: {pe, psr, marketCap, ...}, financials: {...}}
- exits 0 on success, 1 on hard failure (network, unknown ticker)
"""
import json
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_yahoo.py"


def run_script(*args: str) -> dict:
    """Run the script via uv run, return parsed JSON or raise."""
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstdout: {result.stdout}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


def test_us_ticker_returns_expected_shape():
    data = run_script("AAPL")
    assert data["ticker"] == "AAPL"
    assert data["market"] == "US"
    assert isinstance(data["price"], (int, float))
    assert data["price"] > 0
    assert "pe" in data["summary"]
    assert "marketCap" in data["summary"]


def test_jp_ticker_auto_suffix():
    data = run_script("7203")
    assert data["ticker"] == "7203"
    assert data["market"] == "JP"
    assert data["price"] > 0
    assert "pe" in data["summary"]


def test_unknown_ticker_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "ZZZNOTAREALTICKER"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr or "not found" in result.stderr.lower()
