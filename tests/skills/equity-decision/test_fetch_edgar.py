"""Tests for scripts/fetch_edgar.py.

Contract:
- argv[1] is the US ticker
- prints JSON with shape: {ticker, cik, filings: [{form, filedDate, accessionNumber, primaryDocument, url}]}
- only the latest 10-K, 10-Q, and most recent 8-Ks (top 5) need be returned
- exits 1 on unknown ticker
"""
import json
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_edgar.py"


def run_script(*args: str) -> dict:
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


def test_known_us_ticker_returns_filings():
    data = run_script("AAPL")
    assert data["ticker"] == "AAPL"
    assert data["cik"].isdigit() and len(data["cik"]) <= 10
    assert isinstance(data["filings"], list) and len(data["filings"]) > 0
    forms = {f["form"] for f in data["filings"]}
    assert "10-K" in forms, f"no 10-K in filings: {forms}"


def test_unknown_ticker_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "ZZZNOTAREALTICKER"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr or "not found" in result.stderr.lower()
