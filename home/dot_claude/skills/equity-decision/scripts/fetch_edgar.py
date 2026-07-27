#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
# ]
# ///
"""fetch_edgar.py — SEC EDGAR filings for a US ticker.

Usage:
    uv run fetch_edgar.py <TICKER>

Output (stdout, JSON):
    {
      "ticker": "AAPL",
      "cik": "320193",
      "filings": [
        {"form": "10-K", "filedDate": "2024-11-01", "accessionNumber": "...", "primaryDocument": "aapl-20240928.htm", "url": "https://www.sec.gov/..."},
        {"form": "10-Q", ...},
        {"form": "8-K", ...},
        ...
      ]
    }

Returns the most recent 10-K, most recent 10-Q, and top-5 most recent 8-Ks.
Exits 1 if ticker → CIK lookup fails or network errors.
"""
import json
import sys

import requests

UA = "equity-decision-skill (pavegy@gmail.com)"
TICKER_MAP_URL = "https://www.sec.gov/files/company_tickers.json"


def lookup_cik(ticker: str) -> str:
    """Return zero-padded 10-digit CIK for a US ticker."""
    r = requests.get(TICKER_MAP_URL, headers={"User-Agent": UA}, timeout=10)
    r.raise_for_status()
    rows = r.json().values()
    upper = ticker.upper()
    for row in rows:
        if row["ticker"].upper() == upper:
            return str(row["cik_str"]).zfill(10)
    raise ValueError(f"数字取得失敗: EDGAR ticker→CIK miss for {ticker!r}")


def fetch_filings(ticker: str) -> dict:
    cik_padded = lookup_cik(ticker)
    cik = cik_padded.lstrip("0") or "0"
    submissions_url = f"https://data.sec.gov/submissions/CIK{cik_padded}.json"
    r = requests.get(submissions_url, headers={"User-Agent": UA}, timeout=15)
    r.raise_for_status()
    payload = r.json()

    recent = payload["filings"]["recent"]
    rows = list(zip(
        recent["form"],
        recent["filingDate"],
        recent["accessionNumber"],
        recent["primaryDocument"],
    ))

    selected = []
    forms_seen = {"10-K": 0, "10-Q": 0, "8-K": 0}
    for form, filed, accession, prim in rows:
        if form == "10-K" and forms_seen["10-K"] == 0:
            forms_seen["10-K"] += 1
        elif form == "10-Q" and forms_seen["10-Q"] == 0:
            forms_seen["10-Q"] += 1
        elif form == "8-K" and forms_seen["8-K"] < 5:
            forms_seen["8-K"] += 1
        else:
            continue
        acc_clean = accession.replace("-", "")
        selected.append({
            "form": form,
            "filedDate": filed,
            "accessionNumber": accession,
            "primaryDocument": prim,
            "url": f"https://www.sec.gov/Archives/edgar/data/{cik}/{acc_clean}/{prim}",
        })
        if forms_seen["10-K"] >= 1 and forms_seen["10-Q"] >= 1 and forms_seen["8-K"] >= 5:
            break

    return {"ticker": ticker.upper(), "cik": cik, "filings": selected}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_edgar.py <TICKER>", file=sys.stderr)
        return 2
    try:
        data = fetch_filings(sys.argv[1])
    except Exception as e:
        print(f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
