#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "yfinance>=0.2.40",
# ]
# ///
"""fetch_yahoo.py — Yahoo Finance quote + summary metrics for a ticker.

Usage:
    uv run fetch_yahoo.py <TICKER>

Examples:
    uv run fetch_yahoo.py NVDA   # US
    uv run fetch_yahoo.py 7203   # JP (auto .T suffix)

Output (stdout, JSON):
    {
      "ticker": "AAPL",
      "market": "US",
      "price": 192.34,
      "summary": {
        "pe": 31.2,
        "psr": 8.1,
        "marketCap": 3000000000000,
        "beta": 1.25,
        "dividendYield": 0.005
      },
      "financials": {
        "revenue_ttm": 385000000000,
        "operatingIncome_ttm": 120000000000,
        "freeCashFlow_ttm": 100000000000
      }
    }

Exits 1 with a message on stderr if the ticker is unknown or the fetch fails.
"""
import json
import re
import sys

import yfinance as yf


def detect_market(raw_ticker: str) -> tuple[str, str]:
    """Return (yahoo_symbol, market_label)."""
    if re.fullmatch(r"\d{4}", raw_ticker):
        return f"{raw_ticker}.T", "JP"
    return raw_ticker.upper(), "US"


def fetch_summary(raw_ticker: str) -> dict:
    yahoo_symbol, market = detect_market(raw_ticker)
    ticker = yf.Ticker(yahoo_symbol)
    info = ticker.info or {}

    if not info or not info.get("regularMarketPrice"):
        raise ValueError(f"数字取得失敗: ticker {raw_ticker!r} not found on Yahoo Finance")

    return {
        "ticker": raw_ticker,
        "market": market,
        "price": info.get("regularMarketPrice"),
        "summary": {
            "pe": info.get("trailingPE"),
            "psr": info.get("priceToSalesTrailing12Months"),
            "marketCap": info.get("marketCap"),
            "beta": info.get("beta"),
            "dividendYield": info.get("dividendYield"),
        },
        "financials": {
            "revenue_ttm": info.get("totalRevenue"),
            "operatingIncome_ttm": info.get("ebitda"),
            "freeCashFlow_ttm": info.get("freeCashflow"),
        },
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: fetch_yahoo.py <TICKER>", file=sys.stderr)
        return 2
    try:
        data = fetch_summary(sys.argv[1])
    except Exception as e:
        print(f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
