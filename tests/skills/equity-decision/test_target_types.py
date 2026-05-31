"""Tests for fetch_edinet.py document-type targeting.

docTypeCode 140 (四半期報告書) was abolished in the 2024 disclosure reform;
the fetcher targets 120 (有報) + 160 (半期報告書).
"""
from fetch_edinet import TARGET_TYPES, collect_targets


def test_target_types_use_160_not_140():
    assert TARGET_TYPES == ("120", "160")


def test_collect_targets_picks_120_and_160():
    results = [
        {"secCode": "46610", "edinetCode": "E04707", "docTypeCode": "120",
         "docDescription": "有価証券報告書", "submitDateTime": "2025-06-26 15:30", "docID": "S1"},
        {"secCode": "46610", "edinetCode": "E04707", "docTypeCode": "160",
         "docDescription": "半期報告書", "submitDateTime": "2025-12-01 15:00", "docID": "S2"},
        {"secCode": "99990", "edinetCode": "E99999", "docTypeCode": "120",
         "docDescription": "別会社", "submitDateTime": "2025-06-26 15:30", "docID": "S3"},
    ]
    found: dict = {}
    edinet = collect_targets(results, "46610", found)
    assert edinet == "E04707"
    assert set(found) == {"120", "160"}
    assert found["120"]["docID"] == "S1"
    assert found["160"]["docID"] == "S2"
    assert found["120"]["url"].endswith("S1?type=2")


def test_collect_targets_ignores_other_seccodes():
    results = [
        {"secCode": "99990", "edinetCode": "E99999", "docTypeCode": "120", "docID": "X"},
    ]
    found: dict = {}
    edinet = collect_targets(results, "46610", found)
    assert edinet is None
    assert found == {}
