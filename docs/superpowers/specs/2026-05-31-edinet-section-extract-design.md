# Design: EDINET 有報セクション自動抽出

_Date: 2026-05-31 | Target: `~/.claude/skills/equity-decision/scripts/fetch_edinet.py` + workflow docs_

## Problem

`fetch_edinet.py` は書類インデックス（有報の docID + URL）を返すところまでしか自動化されておらず、有報本文の「訴訟事件等」「監査の状況」は人手で取得・解析する必要がある。equity-decision memo の Phase 4 で `⚖️ Regulation/litigation` と `📚 Accounting` が `数字取得失敗` のまま残る原因。

加えて2つの隣接課題:

- `TARGET_TYPES = ("120","140")` の `140`（四半期報告書）は2024年の開示制度改正で廃止済み。早期 break 条件を満たせず常に400日フル探索になり遅い。
- `op` がツールシェル（非対話）で認証できず、キー取得が手動 `!` に依存していた。

## Goal / Done criteria

1. `fetch_edinet.py --sections <docID>` が有報 XBRL から訴訟・監査セクションのプレーンテキストを JSON で返す。
2. オフラインのフィクスチャに対するテストが Red→Green で通る。
3. `TARGET_TYPES` を `("120","160")` に修正し、四半期報告書探索の無駄を除去。
4. `SKILL.md` / `equity-workflow.md` に抽出ステップが結線され、EDINET が通れば Phase 4 が一次情報で自動的に埋まる。
5. キーは op 経由のまま、stdout・設定ファイル平文に露出しない。

## Out of scope (YAGNI)

セグメント数値抽出、事業等のリスク全文、PDF 経路、複数銘柄バッチ。

## Design

### A. CLI surface（後方互換維持）

- 既存: `fetch_edinet.py <4桁コード>` → 書類一覧 JSON（**不変**）。
- 追加: `fetch_edinet.py --sections <docID>` → セクション抽出 JSON。

一覧（安い）と抽出（ZIP DL で重い）を分離。ワークフローは2段: 一覧で有報 docID を得る → `--sections` で本文抽出。

### B. 抽出パイプライン

実物調査（OLC 第65期 S100VY55）で確定した事実:

- 監査 → 専用要素 `jpcrp_cor:AuditsTextBlock`（「(3)【監査の状況】…」）が存在。
- 訴訟 → 専用 TextBlock は**存在しない**。`訴訟|係争|損害賠償` は `BusinessRisksTextBlock` 等に一般言及として散在するのみ。
- → ラベル linkbase parsing は不要。要素 local-name 直指定＋キーワードスキャンで足りる。

1. `GET documents/{docID}?type=1`（XBRL ZIP）をキーヘッダ付きで取得 → `io.BytesIO` → `zipfile.ZipFile`。
2. ZIP 内 `XBRL/PublicDoc/*asr*.xbrl`（有報インスタンス）を特定。
3. `lxml` でパース（依存に `lxml` 追加）。
4. **監査**: local-name == `AuditsTextBlock` の要素を取得 → de-tag。
5. **訴訟**: 全 `*TextBlock` 要素の de-tag テキストを `訴訟|係争|損害賠償` でスキャンし、ヒットしたスニペット＋出所 local-name を収集。
6. de-tag は `lxml.html.fromstring(text).text_content()` ＋空白正規化。
7. 出力:
   ```json
   {
     "docID": "...",
     "sections": {
       "audit": { "element": "AuditsTextBlock", "found": true, "text": "..." },
       "litigation": {
         "found": true,
         "matches": [{ "element": "BusinessRisksTextBlock", "snippet": "..." }]
       }
     }
   }
   ```
   監査要素が無ければ `audit.found=false, text=null`。訴訟ヒット無しは `litigation.found=false, matches=[]`（memo は「重大な係争の個別開示なし」と扱う）。

### C. バグ修正

`TARGET_TYPES = ("120","140")` → `("120","160")`。160=半期報告書。docstring も更新。

### D. テスト（TDD）

- フィクスチャ: OLC 第65期有報の `.xbrl` インスタンスを `scripts/tests/fixtures/` に保存済み（オフライン解析）。ラベル linkbase は不要。
- `test_extract_sections.py`: フィクスチャをパース → 訴訟・監査が期待部分文字列を含むことを assert。
- `TARGET_TYPES` 変更は documents.json の録画レスポンスで軽くカバー。
- 実行: `uv run --with pytest pytest scripts/tests/`。

### E. ワークフロー結線

- `SKILL.md` のデータ fetcher 表に `--sections <docID>` 行を追加。
- `equity-workflow.md` Phase 4 に「有報 docID を `--sections` で抽出し ⚖️訴訟・📚監査 を一次情報で埋める」手順を明記。
- JP フォールバック節に「EDINET が通れば Phase 4 まで自動」と追記。

### F. auth（コード最小）

`get_key()` の `op read` パスはそのまま。`timeout=20`→`timeout=45` に延長（生体認証プロンプトの往復吸収）。前提として 1Password デスクトップアプリの CLI 連携を有効化（ユーザー側作業、ドキュメントに明記）。

## Risks / open questions（調査で解消済み）

- ~~訴訟が専用 TextBlock を持たない可能性~~ → 確定（持たない）。キーワードスキャン方式に決定。
- 有報 XBRL は PublicDoc と AuditDoc を含む。対象は PublicDoc インスタンス（`jpcrp030000-asr-*.xbrl`）。
- 銘柄により監査が監査役会設置/監査等委員会で表現差あり得るが、`AuditsTextBlock` は共通要素なので問題なし。
