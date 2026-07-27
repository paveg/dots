from fetch_edinet import match_ipo_docs


def test_match_filters_by_doctype_and_name_nfkc():
    results = [
        {"docTypeCode": "030", "filerName": "ＧＯ株式会社", "docID": "S1", "docDescription": "有価証券届出書"},
        {"docTypeCode": "120", "filerName": "GO株式会社", "docID": "S2", "docDescription": "有報"},
        {"docTypeCode": "040", "filerName": "GO株式会社", "docID": "S3", "docDescription": "訂正届出書"},
        {"docTypeCode": "030", "filerName": "無関係株式会社", "docID": "S4", "docDescription": "有価証券届出書"},
    ]
    out = match_ipo_docs(results, "GO")
    assert {d["docID"] for d in out} == {"S1", "S3"}
    assert out[0]["url"].endswith("?type=2")


def test_match_empty_name_returns_all_ipo_types():
    results = [
        {"docTypeCode": "030", "filerName": "A社", "docID": "S1"},
        {"docTypeCode": "160", "filerName": "A社", "docID": "S2"},
    ]
    out = match_ipo_docs(results, "")
    assert {d["docID"] for d in out} == {"S1"}
