"""Tests for scripts/fetch_edinet.py.

Contract:
- argv[1] is a 4-digit JP securities code
- prints JSON: {ticker, edinetCode, docs: [{docTypeCode, docDescription, submitDateTime, docID, url}]}
- exits 1 with `数字取得失敗` on stderr when the key is unavailable or lookup fails
- exits 2 on usage error

Integration tests requiring a live EDINET key are skipped automatically when neither
the EDINET_SUBSCRIPTION_KEY env var nor `op read $EDINET_OP_REF` yields a key.
The no-key path is always exercised so CI / agentless sessions still get coverage.
"""
import json
import os
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[3] / "dot_claude" / "skills" / "equity-decision" / "scripts" / "fetch_edinet.py"


def _has_key() -> bool:
    if os.environ.get("EDINET_SUBSCRIPTION_KEY"):
        return True
    op_ref = os.environ.get("EDINET_OP_REF", "op://Personal/EDINET/credential")
    try:
        result = subprocess.run(
            ["op", "read", op_ref], capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0 and bool(result.stdout.strip())
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


requires_key = pytest.mark.skipif(not _has_key(), reason="EDINET key not available")


def run_script(*args: str) -> dict:
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), *args],
        capture_output=True, text=True, timeout=120,
    )
    if result.returncode != 0:
        pytest.fail(f"script exited {result.returncode}\nstderr: {result.stderr}")
    return json.loads(result.stdout)


@requires_key
def test_toyota_returns_yuho():
    data = run_script("7203")
    assert data["ticker"] == "7203"
    assert data["edinetCode"].startswith("E")
    type_codes = {d["docTypeCode"] for d in data["docs"]}
    assert "120" in type_codes


@requires_key
def test_unknown_code_exits_nonzero():
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "0000"],
        capture_output=True, text=True, timeout=120,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr


def test_missing_key_exits_nonzero(monkeypatch):
    """When no key source is available, script must fail loudly."""
    env = os.environ.copy()
    env.pop("EDINET_SUBSCRIPTION_KEY", None)
    env["EDINET_OP_REF"] = "op://nonexistent/path/__"  # force op read failure
    result = subprocess.run(
        ["uv", "run", str(SCRIPT), "7203"],
        capture_output=True, text=True, timeout=10,
        env=env,
    )
    assert result.returncode != 0
    assert "数字取得失敗" in result.stderr
    assert "key unavailable" in result.stderr.lower() or "EDINET_SUBSCRIPTION_KEY" in result.stderr
