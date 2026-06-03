#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
#   "lxml>=5.0",
# ]
# ///
"""fetch_edinet.py — EDINET filings for a JP 4-digit securities code.

Usage:
    uv run fetch_edinet.py <4-digit-secCode>   # list latest filings
    uv run fetch_edinet.py --ipo "<filerName>"     # locate pre-IPO 有価証券届出書 (030/040) by name
    uv run fetch_edinet.py --sections <docID>  # extract 監査/訴訟 from a 有報

Output (stdout, JSON):
    {
      "ticker": "7203",
      "edinetCode": "E02144",
      "docs": [
        {"docTypeCode": "120", "docDescription": "...", "submitDateTime": "...", "docID": "S...", "url": "https://..."},
        {"docTypeCode": "160", ...}
      ]
    }

Walks back up to 400 days from today, listing one day at a time, until both the
latest 有価証券報告書 (docTypeCode 120) and the latest 半期報告書 (docTypeCode 160)
have been collected (or 400 days exhausted). 四半期報告書 (140) was abolished in
the 2024 disclosure reform.

The --sections mode downloads the 有報 XBRL (type=1) for a given docID and returns
{"docID": ..., "sections": {"audit": {...}, "litigation": {...}}}.

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
import io
import json
import os
import re
import subprocess
import sys
import unicodedata
import zipfile
from datetime import date, timedelta
from time import sleep

import requests
from lxml import etree
from lxml import html as lhtml

LITIGATION_RE = re.compile(r"訴訟|係争|損害賠償")
_WS_RE = re.compile(r"\s+")


def _detag(raw: str) -> str:
    if not raw:
        return ""
    try:
        text = lhtml.fromstring(raw).text_content()
    except Exception:
        text = raw
    return _WS_RE.sub(" ", text).strip()


def extract_sections_from_instance(instance_bytes: bytes) -> dict:
    root = etree.fromstring(instance_bytes)
    audit = {"element": "AuditsTextBlock", "found": False, "text": None}
    matches: list[dict] = []
    for el in root.iter():
        local = etree.QName(el).localname
        if "TextBlock" not in local:
            continue
        raw = el.text
        if not raw or not raw.strip():
            continue
        text = _detag(raw)
        if local == "AuditsTextBlock" and not audit["found"]:
            audit = {"element": local, "found": True, "text": text}
        m = LITIGATION_RE.search(text)
        if m:
            start = max(0, m.start() - 60)
            end = min(len(text), m.end() + 120)
            matches.append({"element": local, "snippet": text[start:end]})
    return {
        "audit": audit,
        "litigation": {"found": bool(matches), "matches": matches},
    }


def _instance_from_zip(zip_bytes: bytes) -> bytes:
    zf = zipfile.ZipFile(io.BytesIO(zip_bytes))
    for name in zf.namelist():
        if "/PublicDoc/" in name and name.endswith(".xbrl"):
            return zf.read(name)
    raise ValueError("数字取得失敗: PublicDoc .xbrl not found in EDINET ZIP")


def fetch_sections(doc_id: str) -> dict:
    key = get_key()
    url = f"https://disclosure.edinet-fsa.go.jp/api/v2/documents/{doc_id}?type=1"
    r = requests.get(url, headers={KEY_HEADER: key}, timeout=60)
    r.raise_for_status()
    instance = _instance_from_zip(r.content)
    return {"docID": doc_id, "sections": extract_sections_from_instance(instance)}


API = "https://disclosure.edinet-fsa.go.jp/api/v2/documents.json"
TARGET_TYPES = ("120", "160")  # 120=有報, 160=半期報告書（140 四半期報告書は2024改正で廃止）
IPO_TYPES = ("030", "040")  # 030=有価証券届出書, 040=訂正有価証券届出書
IPO_DAYS_BACK = 180  # 届出書 is typically filed ~1 month pre-listing; 訂正 later


def _norm(s: str) -> str:
    return unicodedata.normalize("NFKC", s or "").replace(" ", "").lower()


def match_ipo_docs(results: list, name_substring: str) -> list[dict]:
    needle = _norm(name_substring)
    out = []
    for item in results or []:
        if item.get("docTypeCode") not in IPO_TYPES:
            continue
        if needle and needle not in _norm(item.get("filerName", "")):
            continue
        out.append({
            "docTypeCode": item.get("docTypeCode"),
            "filerName": item.get("filerName", ""),
            "docDescription": item.get("docDescription", ""),
            "submitDateTime": item.get("submitDateTime", ""),
            "docID": item.get("docID", ""),
            "url": _doc_url(item.get("docID", "")),
        })
    return out


MAX_DAYS_BACK = 400
KEY_HEADER = "Ocp-Apim-Subscription-Key"
DEFAULT_OP_REF = "op://Personal/EDINET/credential"


def get_key() -> str:
    env_key = os.environ.get("EDINET_SUBSCRIPTION_KEY", "").strip()
    if env_key:
        return env_key
    op_ref = os.environ.get("EDINET_OP_REF", DEFAULT_OP_REF)
    try:
        # op read via Desktop integration prompts biometrics; allow time to approve.
        result = subprocess.run(
            ["op", "read", op_ref],
            capture_output=True,
            text=True,
            timeout=45,
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


def collect_targets(results: list, code_padded: str, found: dict) -> str | None:
    edinet_code = None
    for item in results or []:
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
    return edinet_code


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

        ec = collect_targets(payload.get("results", []), code_padded, found)
        if ec and edinet_code is None:
            edinet_code = ec

        if all(t in found for t in TARGET_TYPES):
            break
        sleep(0.3)

    if edinet_code is None:
        raise ValueError(
            f"数字取得失敗: EDINET secCode→edinetCode miss for {sec_code!r}"
        )

    docs = [found[t] for t in TARGET_TYPES if t in found]
    return {"ticker": sec_code, "edinetCode": edinet_code, "docs": docs}


def fetch_ipo(name_substring: str) -> dict:
    key = get_key()
    headers = {KEY_HEADER: key}
    seen: dict[str, dict] = {}
    for day in iter_days(date.today(), IPO_DAYS_BACK):
        params = {"date": day.isoformat(), "type": "2"}
        r = requests.get(API, headers=headers, params=params, timeout=15)
        r.raise_for_status()
        payload = r.json()
        meta = str(payload.get("metadata", {}).get("status", ""))
        if meta not in ("", "200"):
            raise ValueError(f"数字取得失敗: EDINET API rejected key — {payload}")
        for doc in match_ipo_docs(payload.get("results", []), name_substring):
            if doc["docID"] and doc["docID"] not in seen:
                seen[doc["docID"]] = doc
        sleep(0.3)
    if not seen:
        raise ValueError(
            f"数字取得失敗: no 有価証券届出書/訂正 found for filerName~={name_substring!r} "
            f"in last {IPO_DAYS_BACK} days. Paste the 目論見書/届出書 URL to proceed."
        )
    docs = sorted(seen.values(), key=lambda d: d["submitDateTime"])
    return {"query": name_substring, "docs": docs}


def main() -> int:
    args = sys.argv[1:]
    if len(args) == 2 and args[0] == "--sections":
        try:
            data = fetch_sections(args[1])
        except Exception as e:
            msg = f"{e}" if str(e).startswith("数字取得失敗") else f"数字取得失敗: {e}"
            print(msg, file=sys.stderr)
            return 1
        json.dump(data, sys.stdout, ensure_ascii=False)
        return 0
    if len(args) == 2 and args[0] == "--ipo":
        try:
            data = fetch_ipo(args[1])
        except Exception as e:
            msg = f"{e}" if str(e).startswith("数字取得失敗") else f"数字取得失敗: {e}"
            print(msg, file=sys.stderr)
            return 1
        json.dump(data, sys.stdout, ensure_ascii=False)
        return 0
    if len(args) != 1:
        print(
            "usage: fetch_edinet.py <4-digit-secCode> | --ipo <filerName> | --sections <docID>",
            file=sys.stderr,
        )
        return 2
    try:
        data = fetch_docs(args[0])
    except Exception as e:
        print(f"{e}" if str(e).startswith("数字取得失敗") else f"数字取得失敗: {e}", file=sys.stderr)
        return 1
    json.dump(data, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
