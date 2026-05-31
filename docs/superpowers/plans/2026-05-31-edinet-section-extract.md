# EDINET 有報セクション自動抽出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `fetch_edinet.py --sections <docID>` で有報 XBRL から監査セクション本文と訴訟関連スニペットを JSON 抽出し、equity-decision memo の Phase 4 を一次情報で自動的に埋められるようにする。

**Architecture:** 既存の一覧モード（`<code>` → 書類インデックス）は不変のまま、`--sections <docID>` モードを追加。type=1 XBRL ZIP を落とし、PublicDoc インスタンスを lxml でパース。監査は要素 `AuditsTextBlock` 直指定、訴訟は全 TextBlock を `訴訟|係争|損害賠償` でスキャン。純粋関数 `extract_sections_from_instance(bytes)` をオフラインのフィクスチャでTDD。

**Tech Stack:** Python 3.11+ (uv single-file script, PEP723), requests, lxml, pytest。

**Pre-req:** 1Password デスクトップアプリの CLI 連携が有効（`op read op://Personal/EDINET/credential` が非対話で通る）。フィクスチャ `scripts/tests/fixtures/jpcrp030000-asr-001_E04707-000_2025-03-31_01_2025-06-26.xbrl`（OLC 第65期、4.8MB）は配置済み。

**Note on commits:** このスキルディレクトリ（`~/.claude/skills/equity-decision`）は git 管理外。各タスクの「Commit」ステップは git init 済みの場合のみ実行（未管理ならスキップしてよい）。

---

### Task 1: lxml 依存と抽出ヘルパ（監査）

**Files:**
- Modify: `scripts/fetch_edinet.py`（PEP723 ヘッダ + 新規関数）
- Create: `scripts/tests/test_extract_sections.py`
- Test fixture (already present): `scripts/tests/fixtures/jpcrp030000-asr-001_E04707-000_2025-03-31_01_2025-06-26.xbrl`

- [ ] **Step 1: 失敗するテストを書く**

Create `scripts/tests/test_extract_sections.py`:

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fetch_edinet import extract_sections_from_instance  # noqa: E402

FIXTURE = (
    Path(__file__).parent
    / "fixtures"
    / "jpcrp030000-asr-001_E04707-000_2025-03-31_01_2025-06-26.xbrl"
)


def test_audit_section_extracted():
    out = extract_sections_from_instance(FIXTURE.read_bytes())
    assert out["audit"]["found"] is True
    assert out["audit"]["element"] == "AuditsTextBlock"
    assert "監査の状況" in out["audit"]["text"]
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/test_extract_sections.py -v`
Expected: FAIL — `ImportError: cannot import name 'extract_sections_from_instance'`

- [ ] **Step 3: 最小実装（PEP723 に lxml 追加 + 抽出関数）**

`scripts/fetch_edinet.py` の PEP723 dependencies を更新:

```python
# dependencies = [
#   "requests>=2.31",
#   "lxml>=5.0",
# ]
```

`import requests` の直後に追加:

```python
import re
from lxml import etree, html as lhtml

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
```

- [ ] **Step 4: テストが通ることを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/test_extract_sections.py -v`
Expected: PASS (`test_audit_section_extracted`)

- [ ] **Step 5: Commit（git管理時のみ）**

```bash
git add scripts/fetch_edinet.py scripts/tests/test_extract_sections.py
git commit -m "feat(edinet): extract 監査の状況 from 有報 XBRL"
```

---

### Task 2: 訴訟キーワードスキャンのテスト

**Files:**
- Modify: `scripts/tests/test_extract_sections.py`（テスト追加のみ。実装は Task 1 で完了済み）

- [ ] **Step 1: 失敗しないことを期待するテストを追加**（実装済み機能の固定化）

`test_extract_sections.py` に追記:

```python
def test_litigation_scan_returns_matches():
    out = extract_sections_from_instance(FIXTURE.read_bytes())
    lit = out["litigation"]
    assert lit["found"] is True
    assert all({"element", "snippet"} <= set(m) for m in lit["matches"])
    assert any(
        ("訴訟" in m["snippet"]) or ("係争" in m["snippet"]) or ("損害賠償" in m["snippet"])
        for m in lit["matches"]
    )


def test_litigation_no_dedicated_textblock_element():
    # 有報タクソノミに訴訟専用要素は無い前提を固定。
    # OLC では BusinessRisksTextBlock 等にキーワードが散在する。
    out = extract_sections_from_instance(FIXTURE.read_bytes())
    elems = {m["element"] for m in out["litigation"]["matches"]}
    assert "BusinessRisksTextBlock" in elems
```

- [ ] **Step 2: テストが通ることを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/test_extract_sections.py -v`
Expected: PASS（3 tests）

- [ ] **Step 3: Commit（git管理時のみ）**

```bash
git add scripts/tests/test_extract_sections.py
git commit -m "test(edinet): pin litigation keyword-scan behavior"
```

---

### Task 3: `--sections <docID>` CLI モード

**Files:**
- Modify: `scripts/fetch_edinet.py`（ZIP取得関数 + main 引数分岐）

- [ ] **Step 1: ZIP→インスタンス抽出とダウンロード関数を追加**

`extract_sections_from_instance` の下に追加:

```python
import io
import zipfile


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
```

（`io`/`zipfile` は既存 import に無ければファイル冒頭の import 群へ移動してよい。）

- [ ] **Step 2: main() に `--sections` 分岐を追加**

既存 `main()` の先頭を以下に置換:

```python
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
    if len(args) != 1:
        print(
            "usage: fetch_edinet.py <4-digit-secCode> | --sections <docID>",
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
```

- [ ] **Step 3: ライブ smoke test（要 op 認証 / ネット）**

Run: `cd ~/.claude/skills/equity-decision && uv run scripts/fetch_edinet.py --sections S100VY55 | python3 -m json.tool | head -30`
Expected: JSON。`sections.audit.found == true`、`sections.audit.text` が「監査の状況」を含む、`sections.litigation.matches` が非空。

- [ ] **Step 4: 既存一覧モードが壊れていないことを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run scripts/fetch_edinet.py 4661 | python3 -m json.tool`
Expected: 従来どおり `edinetCode` と `docs`（有報）を含む JSON。

- [ ] **Step 5: Commit（git管理時のみ）**

```bash
git add scripts/fetch_edinet.py
git commit -m "feat(edinet): add --sections <docID> mode"
```

---

### Task 4: `TARGET_TYPES` 140→160 修正（四半期報告書廃止対応）

**Files:**
- Modify: `scripts/fetch_edinet.py`（定数 + 日次マッチ部の小リファクタ + テスト）
- Modify: `scripts/tests/test_extract_sections.py`（または新規 `test_target_types.py`）

- [ ] **Step 1: 日次マッチを純粋関数へ抽出して失敗テストを書く**

`scripts/tests/test_target_types.py` を新規作成:

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fetch_edinet import TARGET_TYPES, collect_targets  # noqa: E402


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
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/test_target_types.py -v`
Expected: FAIL — `ImportError: cannot import name 'collect_targets'`（かつ TARGET_TYPES がまだ 140）

- [ ] **Step 3: 定数変更 + 純粋関数を実装し fetch_docs から呼ぶ**

定数を変更:

```python
TARGET_TYPES = ("120", "160")  # 120=有報, 160=半期報告書（140 四半期報告書は2024改正で廃止）
```

`fetch_docs` の日次ループ内マッチ処理を関数化して追加:

```python
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
```

`fetch_docs` 内の該当 for ループ本体を以下に置換:

```python
        ec = collect_targets(payload.get("results", []), code_padded, found)
        if ec and edinet_code is None:
            edinet_code = ec
```

- [ ] **Step 4: テストが通ることを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/test_target_types.py -v`
Expected: PASS（2 tests）

- [ ] **Step 5: Commit（git管理時のみ）**

```bash
git add scripts/fetch_edinet.py scripts/tests/test_target_types.py
git commit -m "fix(edinet): replace deprecated docType 140 with 160 (半期報告書)"
```

---

### Task 5: `op read` timeout を 45s に延長

**Files:**
- Modify: `scripts/fetch_edinet.py`（`get_key()` 内 `timeout=20` → `timeout=45`）

- [ ] **Step 1: 値を変更**

`get_key()` 内:

```python
        result = subprocess.run(
            ["op", "read", op_ref],
            capture_output=True,
            text=True,
            timeout=45,
        )
```

コメントも更新: `# op read via Desktop integration prompts biometrics; allow time to approve.`

- [ ] **Step 2: 既存呼び出しが通ることを確認**

Run: `cd ~/.claude/skills/equity-decision && uv run scripts/fetch_edinet.py 4661 >/dev/null && echo OK`
Expected: `OK`（認証→一覧取得が成功）

- [ ] **Step 3: Commit（git管理時のみ）**

```bash
git add scripts/fetch_edinet.py
git commit -m "chore(edinet): bump op read timeout for biometric approval"
```

---

### Task 6: ワークフロー結線（SKILL.md / equity-workflow.md）

**Files:**
- Modify: `SKILL.md`（データ fetcher 表 + JP フォールバック節）
- Modify: `references/equity-workflow.md`（Phase 4 手順）

- [ ] **Step 1: SKILL.md のデータ fetcher 表に行を追加**

「JP code → EDINET filings」行の直後に追加:

```markdown
| JP 有報本文 → 訴訟・監査 | `uv run scripts/fetch_edinet.py --sections {docID}` | `sections.audit`（監査の状況本文）+ `sections.litigation.matches`（訴訟/係争/損害賠償スニペット） |
```

- [ ] **Step 2: SKILL.md の JP フォールバック節に追記**

「## JP fallback when EDINET is unavailable」節の冒頭付近に1行追加:

```markdown
> EDINET が通る場合: まず `fetch_edinet.py {code}` で有報 docID を取得し、続けて `fetch_edinet.py --sections {docID}` で Phase 4 の ⚖️訴訟・📚監査 を一次情報から埋める（このとき Phase 4 は手動補完不要）。
```

- [ ] **Step 3: equity-workflow.md の Phase 4  filling rules に追記**

「## Filling rules」の最初の箇条書き群に追加:

```markdown
- **Phase 4（JP）**: EDINET が使える場合、`fetch_edinet.py --sections {docID}` の出力で `⚖️ Regulation/litigation` と `📚 Accounting` を埋める。`sections.audit.text` から監査体制（監査役会/監査等委員会、会計監査人、非監査報酬の有無）を要約。`sections.litigation.found == false` または事業リスクの一般言及のみなら「重大な係争の個別開示なし」と記す。捏造禁止は同様に適用。
```

- [ ] **Step 4: 結線の目視確認**

Run: `cd ~/.claude/skills/equity-decision && grep -n "\-\-sections" SKILL.md references/equity-workflow.md`
Expected: 3 箇所（SKILL 表 / SKILL フォールバック / workflow Phase4）でヒット。

- [ ] **Step 5: Commit（git管理時のみ）**

```bash
git add SKILL.md references/equity-workflow.md
git commit -m "docs(edinet): wire --sections into Phase 4 workflow"
```

---

### Task 7: 全テスト緑 + dev ツール整理

**Files:**
- Modify/Delete: `scripts/_devtools/fetch_fixture.py`（残置 or 削除の判断）

- [ ] **Step 1: 全テストを実行**

Run: `cd ~/.claude/skills/equity-decision && uv run --with pytest --with lxml --with requests pytest scripts/tests/ -v`
Expected: PASS（test_extract_sections の3件 + test_target_types の2件 = 5 tests）

- [ ] **Step 2: dev ツールの扱いを決める**

`scripts/_devtools/fetch_fixture.py` はフィクスチャ再生成用の一回限りツール。残すなら docstring に「フィクスチャ更新時のみ使用」と明記、不要なら削除:

```bash
rm -rf scripts/_devtools   # 残置する場合はこの行を実行しない
```

- [ ] **Step 3: Commit（git管理時のみ）**

```bash
git add -A
git commit -m "chore(edinet): finalize fixture tooling"
```

---

## Self-Review

- **Spec coverage**: A 抽出CLI → Task3 / B XBRLパイプライン（監査=AuditsTextBlock, 訴訟=keyword scan）→ Task1,2 / C 140→160 → Task4 / D TDD+fixture → Task1,2,4,7 / E ワークフロー結線 → Task6 / F auth timeout → Task5。全項目に対応タスクあり。
- **Placeholder scan**: 各コードステップに実コードを記載。実物フィクスチャで検証済み（AuditsTextBlock 存在・監査の状況本文・訴訟は BusinessRisksTextBlock 等に散在）。
- **Type consistency**: `extract_sections_from_instance(bytes)->dict`、`collect_targets(results,code_padded,found)->str|None`、`fetch_sections(doc_id)->dict`、`_instance_from_zip(bytes)->bytes`、`_detag(str)->str` は全タスクで整合。出力キー `audit.{element,found,text}` / `litigation.{found,matches[].{element,snippet}}` は spec の出力例と一致。
