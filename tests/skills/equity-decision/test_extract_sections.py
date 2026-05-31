"""Tests for fetch_edinet.py --sections extraction (監査の状況 / 訴訟).

Offline unit tests use a tiny synthetic XBRL instance — what matters is the
element local-name (AuditsTextBlock / BusinessRisksTextBlock), not real filing
size. The real-filing path is covered by the @requires_key live test in
test_fetch_edinet.py.
"""
import io
import zipfile

from fetch_edinet import (
    _instance_from_zip,
    extract_sections_from_instance,
)

# Minimal XBRL: one AuditsTextBlock (監査の状況) + one BusinessRisksTextBlock (訴訟).
# TextBlock bodies are escaped XHTML, exactly as EDINET stores them.
_XBRL_WITH_AUDIT = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" '
    'xmlns:jpcrp_cor="http://disclosure.edinet-fsa.go.jp/taxonomy/jpcrp/cor">'
    '<jpcrp_cor:AuditsTextBlock contextRef="c">'
    "&lt;p&gt;(3) 監査の状況 当社は監査役会設置会社です&lt;/p&gt;"
    "</jpcrp_cor:AuditsTextBlock>"
    '<jpcrp_cor:BusinessRisksTextBlock contextRef="c">'
    "&lt;p&gt;事業等のリスク 当社が損害賠償請求の訴訟を受ける可能性&lt;/p&gt;"
    "</jpcrp_cor:BusinessRisksTextBlock>"
    "</xbrli:xbrl>"
).encode("utf-8")

# Same shape but no AuditsTextBlock and no litigation keyword.
_XBRL_NO_AUDIT = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" '
    'xmlns:jpcrp_cor="http://disclosure.edinet-fsa.go.jp/taxonomy/jpcrp/cor">'
    '<jpcrp_cor:DescriptionOfBusinessTextBlock contextRef="c">'
    "&lt;p&gt;事業の内容&lt;/p&gt;"
    "</jpcrp_cor:DescriptionOfBusinessTextBlock>"
    "</xbrli:xbrl>"
).encode("utf-8")


def test_audit_section_extracted():
    out = extract_sections_from_instance(_XBRL_WITH_AUDIT)
    assert out["audit"]["found"] is True
    assert out["audit"]["element"] == "AuditsTextBlock"
    assert "監査の状況" in out["audit"]["text"]


def test_litigation_scan_returns_matches():
    out = extract_sections_from_instance(_XBRL_WITH_AUDIT)
    lit = out["litigation"]
    assert lit["found"] is True
    assert all({"element", "snippet"} <= set(m) for m in lit["matches"])
    assert any("訴訟" in m["snippet"] for m in lit["matches"])
    assert any(m["element"] == "BusinessRisksTextBlock" for m in lit["matches"])


def test_audit_not_found_returns_none_text():
    out = extract_sections_from_instance(_XBRL_NO_AUDIT)
    assert out["audit"]["found"] is False
    assert out["audit"]["text"] is None
    assert out["litigation"]["found"] is False
    assert out["litigation"]["matches"] == []


def test_instance_from_zip_raises_when_no_publicdoc():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("XBRL/AuditDoc/something.xbrl", b"<x/>")
    try:
        _instance_from_zip(buf.getvalue())
        raised = None
    except ValueError as e:
        raised = str(e)
    assert raised is not None
    assert raised.startswith("数字取得失敗")


def test_instance_from_zip_returns_publicdoc():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("XBRL/PublicDoc/jpcrp030000-asr.xbrl", _XBRL_WITH_AUDIT)
        zf.writestr("XBRL/AuditDoc/jpaud.xbrl", b"<x/>")
    instance = _instance_from_zip(buf.getvalue())
    assert b"AuditsTextBlock" in instance
