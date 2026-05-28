#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
# ]
# ///
"""fetch_edinet.py — EDINET filings for a JP 4-digit securities code.

Usage:
    uv run fetch_edinet.py <4-digit-secCode>

Output (stdout, JSON):
    {
      "ticker": "7203",
      "edinetCode": "E02144",
      "docs": [
        {"docTypeCode": "120", "docDescription": "...", "submitDateTime": "...", "docID": "S...", "url": "https://..."},
        {"docTypeCode": "140", ...}
      ]
    }

Walks back up to 400 days from today, listing one day at a time, until both the
latest 有価証券報告書 (docTypeCode 120) and the latest 四半期報告書 (docTypeCode 140)
have been collected (or 400 days exhausted).

Authentication:
    The EDINET v2 API requires the `Ocp-Apim-Subscription-Key` header. Obtain a
    free key from https://disclosure2.edinet-fsa.go.jp/ and provide it via:
      1. environment variable EDINET_SUBSCRIPTION_KEY, or
      2. 1Password — defaults to op://Personal/EDINET/credential. Override with
         the EDINET_OP_REF environment variable.

Exit codes:
    0 — JSON written to stdout
    1 — fetch / auth / lookup failed (message on stderr begins with `数字取得失敗`)
    2 — usage error
"""
import json
import os
import subprocess
import sys
from datetime import date, timedelta
from time import sleep

import requests

API = "https://disclosure.edinet-fsa.go.jp/api/v2/documents.json"
TARGET_TYPES = ("120", "140")
MAX_DAYS_BACK = 400
KEY_HEADER = "Ocp-Apim-Subscription-Key"
DEFAULT_OP_REF = "op://Personal/EDINET/credential"


def get_key() -> str:
    env_key = os.environ.get("EDINET_SUBSCRIPTION_KEY", "").strip()
    if env_key:
        return env_key
    op_ref = os.environ.get("EDINET_OP_REF", DEFAULT_OP_REF)
    try:
        result = subprocess.run(
            ["op", "read", op_ref],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        result = None
    if result is not None and result.returncode == 0:
        op_key = result.stdout.strip()
        if op_key:
            return op_key
    raise ValueError(
        "数字取得失敗: EDINET key unavailable. Set EDINET_SUBSCRIPTION_KEY env var, "
        "or store in 1Password at op://Personal/EDINET/credential "
        "(override path via EDINET_OP_REF env)."
    )


def iter_days(start: date, days: int):
    for offset in range(days):
        yield start - timedelta(days=offset)


def _doc_url(doc_id: str) -> str:
    return f"https://disclosure.edinet-fsa.go.jp/api/v2/documents/{doc_id}?type=2"


def fetch_docs(sec_code: str) -> dict:
    key = get_key()
    code_padded = sec_code.zfill(4) + "0"
    headers = {KEY_HEADER: key}

    found: dict[str, dict] = {}
    edinet_code: str | None = None

    for day in iter_days(date.today(), MAX_DAYS_BACK):
        params = {"date": day.isoformat(), "type": "2"}
        r = requests.get(API, headers=headers, params=params, timeout=15)
        r.raise_for_status()
        payload = r.json()

        metadata_status = str(payload.get("metadata", {}).get("status", ""))
        top_status = str(payload.get("StatusCode", ""))
        if metadata_status not in ("", "200") or top_status not in ("", "200"):
            raise ValueError(
                f"数字取得失敗: EDINET API rejected key — {payload}"
            )

        for item in payload.get("results", []) or []:
            if item.get("secCode") != code_padded:
                continue
            if edinet_code is None and item.get("edinetCode"):
                edinet_code = item["edinetCode"]
            doc_type = item.get("docTypeCode")
            if doc_type in TARGET_TYPES and doc_type not in found:
                found[doc_type] = {
                    "docTypeCode": doc_type,
                    "docDescription": item.get("docDescription", ""),
                    "submitDateTime": item.get("submitDateTime", ""),
                    "docID": item.get("docID", ""),
                    "url": _doc_url(item.get("docID", "")),
                }

        if all(t in found for t in TARGET_TYPES):
            break
        sleep(0.3)

    if edinet_code is None:
        raise ValueError(
            f"数字取得失敗: EDINET secCode→edinetCode miss for {sec_code!r}"
        )

    docs = [found[t] for t in TARGET_TYPES if t in found]
    return {"ticker": sec_code, "edinetCode": edinet_code, "docs": docs}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_edinet.py <4-digit-secCode>", file=sys.stderr)
        return 2
    try:
        data = fetch_docs(sys.argv[1])
    except Exception as e:
        print(f"{e}" if str(e).startswith("数字取得失敗") else f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
