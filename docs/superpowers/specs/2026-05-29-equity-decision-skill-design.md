# Spec: `equity-decision` skill

**Status**: Approved (brainstorming complete) **Date**: 2026-05-29 **Author**: Ryota (with Claude) **Skill location**: `~/.local/share/chezmoi/dot_claude/skills/equity-decision/` **Origin**: Adapted from [`anthropics/financial-services`](https://github.com/anthropics/financial-services) (Apache 2.0)

## Problem

個人投資 (主に米株 + 日本株 + ETF / インデックス) の購入判断で時間を食う 4 ステップ — ファンダ読解 / バリュエーション妥当性 / リスク洗い出し / 論点整理 — を 1 コマンドで一気通貫させたい。長期保有・成長株・イベントドリブンの 3 スタイルをまたぐ。配当 / インカム重視は対象外。

## Non-goals

- 法的・税務的な投資助言ではない。出力にディスクレーマー記載必須
- 香港・上海・欧州・暗号通貨・商品・個別債券は対象外
- 自動ウォッチリスト / アラート / cron は別 skill / 別 issue
- 既存ポートフォリオ管理ツールとの統合
- ガイダンス / コンセンサス予想の取得 (paid data の世界)

## Approach

**Approach C (一発 + 深掘りポート)** を採用。初手レポートで全 phase の要点を 1 画面サマリで出す。末尾に「深掘りする？」5 件を提示し、必要なものだけ追加ターンで掘る。

理由: A (対話的 walkthrough) は判断スピード優先に逆行、B (一発レポート) は何が決定打だったか見えにくく token も食う。C は速度と詳細掘りの折衷で最も「判断を簡単にする」要件にフィット。

## Architecture

### 呼び出しインタフェース

```
/equity-decision NVDA
/equity-decision 7203                                # JP 4-digit
/equity-decision VTI                                  # ETF
/equity-decision NVDA "DC 売上の頭打ちが気になる"      # ticker + 仮説
/equity-decision https://www.sec.gov/.../10-K.htm     # URL 直渡し
/equity-decision --ja 9434                            # 強制 JP 指定
/equity-decision --no-cache NVDA                      # 強制再フェッチ
```

### ルーティング

- `^\d{4}$` → JP (EDINET + 決算短信)
- `^[A-Z]{1,5}$` → US (EDGAR + Yahoo Finance)
- URL → ページ内容からシンボル類推
- ETF / 個別株: `yfinance` の `quoteType` で判定 (ETF / MUTUALFUND vs EQUITY)

### ディレクトリ構成

```
dot_claude/skills/equity-decision/
├── SKILL.md                    # エントリ、ルーティング、出力テンプレ参照
├── README.md                   # ユーザ向け使用例
├── references/
│   ├── equity-workflow.md      # 個別株 5 phase 詳細
│   ├── etf-workflow.md         # ETF 4 phase 詳細
│   ├── dcf-rubric.md           # WACC・成長率・terminal value の既定値 / ガード
│   ├── growth-stock-checks.md  # SBC, NRR, Rule-of-40 等
│   ├── risk-taxonomy.md        # 5 軸 (Debt / Competition / Regulation / Accounting / Concentration)
│   └── data-sources.md         # EDGAR / EDINET / Yahoo / Damodaran クエリ集
└── scripts/
    ├── fetch_yahoo.py          # yfinance ラッパー: stdout に JSON
    ├── fetch_edgar.py          # SEC EDGAR submissions API
    ├── fetch_edinet.py         # EDINET 書類取得 API
    ├── fetch_holdings.py       # ETF holdings CSV (運用会社別 URL 解決)
    └── industry_medians.py     # Damodaran 公開データ
```

## 個別株 workflow (5 phase)

`/equity-decision NVDA` を叩いた初手レポートが必ず含む 5 phase + 上限。

| Phase                      | 中身                                                                              | 上限          | データ源                  |
| -------------------------- | --------------------------------------------------------------------------------- | ------------- | ------------------------- |
| 1. Business snapshot       | 事業 3 行 + セグメント売上比率 + 主要顧客集中度                                   | 80 字 + 表    | 10-K Item 1 / 有報 / 短信 |
| 2. Fundamentals (3y)       | 売上成長率, GP/OP/NP, FCF margin, ROIC, ND/EBITDA, 希薄化                         | 表 1 個       | Yahoo + 直近 10-K/10-Q    |
| 3. Valuation triangulation | (a) Multiples (PER/PSR/EV-EBITDA/EV-FCF) vs 業種中央値, (b) DCF 簡易版 3 シナリオ | レンジ + 一言 | Yahoo + Damodaran         |
| 4. Risks (5 軸スキャン)    | Debt / Competition / Regulation / Accounting / Concentration を各 1 行            | 5 行          | 10-K Item 1A / 有報       |
| 5. Verdict                 | Thesis 3 行 + Invalidation KPI 3 件 + Verdict (Buy/Watch/Pass) + Sizing + Horizon | 150 字        | 上記合成                  |

末尾固定:

```
深掘りする？
  1. valuation を変数いじって再計算 (WACC / terminal / 売上 CAGR)
  2. risks #N をフィリングから根拠引用つきで再構成
  3. 競合 X 社との指標横並び比較
  4. 直近 3 四半期の earnings call 言及トピック差分
  5. KPI モニタを 5 つに絞り込む
```

### Phase 5 — Invalidation の縛り

崩壊条件は **検証可能な数字 KPI** に縛る。「市場が悪くなったら」のような曖昧な記述は不可。例: ✓ "Q3 で Data Center YoY が +30% を下回る" / ✗ "AI ブームが終わる"

## ETF / Index workflow (4 phase)

| Phase                   | 中身                                                                        | 上限      | データ源                      |
| ----------------------- | --------------------------------------------------------------------------- | --------- | ----------------------------- |
| 1. 商品スナップショット | ベンチマーク, 運用会社, 設定日, AUM, 運用方式 (フルレプリ / サンプリング)   | 表 1 個   | Yahoo + 運用会社 product page |
| 2. コスト構造           | TER + 同等 ETF 3-5 本比較, bid-ask spread, 1y tracking error                | 比較表    | Yahoo / Stooq + fact sheet    |
| 3. Holdings             | 上位 10 銘柄, セクター, 地域, 集中度 (HHI or top10 比率)                    | 表 + 1 行 | 運用会社 CSV / Yahoo Holdings |
| 4. Fit                  | ポートフォリオ重複 (optional), 3y/5y/10y total return, NISA 扱い, FX リスク | 4 行      | 上記 + ユーザ memo            |

Verdict ラベル: **Core / Satellite / Pass** (個別株とは別)

末尾固定:

```
深掘りする？
  1. 類似 ETF 3-5 本の横並び比較
  2. tracking error 推移
  3. NISA 成長投資枠 / つみたて枠での扱い
  4. 既存保有との重複計算 (要 portfolio JSON)
```

## 出力フォーマット

詳細テンプレは `references/equity-workflow.md` と `references/etf-workflow.md` に格納。テンプレ要件:

- 100-200 行が上限 (ターミナル 1 画面)
- Verdict 行は最後に固定書式 → `grep` 履歴比較できる
- 末尾の「深掘りする？」5 (個別株) / 4 (ETF) 件を必ず提示
- ディスクレーマー (投資助言ではない / データ取得失敗時は明示) を冒頭または末尾に 1 行

## データ取得戦略

### ソース

| 用途                      | US                        | JP                       | ETF                  |
| ------------------------- | ------------------------- | ------------------------ | -------------------- |
| 株価・主要指標            | Yahoo Finance             | Yahoo Finance Japan      | Yahoo Finance        |
| 通期 (10-K / 有報)        | SEC EDGAR submissions API | EDINET 書類取得 API      | —                    |
| 四半期 (10-Q / 短信)      | EDGAR                     | TDnet 短信 HTML / EDINET | —                    |
| 重要事実 (8-K / 適時開示) | EDGAR                     | TDnet                    | —                    |
| 業種中央値                | NYU Damodaran             | Damodaran (US proxy)     | Morningstar category |
| ETF holdings              | —                         | —                        | 運用会社公式 CSV     |

### スクリプト規約

- 全スクリプトは `uv run` で動く単体 Python (PEP 723 inline metadata)
- 入力: argv (ticker / URL)、出力: JSON to stdout
- 依存: yfinance, requests, beautifulsoup4 のみ。devbox / 環境変数不要
- Claude は `Bash` でスクリプトを呼んで結果を受け取る (subagent 風)

### キャッシュ

- `~/.cache/equity-decision/{source}-{ticker}-{YYYY-MM-DD}.json`
- TTL 24h
- `--no-cache` で強制再取得

### 失敗時挙動

- yfinance rate limit → 1 回 retry → ダメなら memo に「価格データ取得失敗」を明示
- EDGAR / EDINET シンボル解決失敗 → Phase 1 で明示
- ETF holdings CSV フォーマット変化 → "holdings not available, manual entry required" + 続行
- **Claude による hallucinate 補完は禁止**: SKILL.md に明示

## Phasing

| Phase        | 内容                                                                                                                           | リリース     |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------ | ------------ |
| A — Skeleton | SKILL.md + references/ ドキュメント一式。fetcher 無し、Claude が手で数字埋め。これだけで「ユーザが手で数字を渡す」フローは動く | v1 内        |
| B — Fetchers | scripts/ に Yahoo / EDGAR / EDINET の最小フェッチャ。`uv run` で動く単体スクリプト                                             | v1 内        |
| C — ETF      | ETF テンプレ + holdings フェッチャ + Core/Satellite/Pass verdict                                                               | v1.1 (別 PR) |
| D — Polish   | 24h cache, `--no-cache`, 失敗時メッセージ整備, Stooq フォールバック, README 使用例                                             | v1.2 (別 PR) |

## Done criteria (v1 = Phase A + B + 個別株のみ)

1. `~/.claude/skills/equity-decision/SKILL.md` deploy 済み
2. `/equity-decision NVDA` で個別株 5 phase memo が出る (fetcher で数字埋め)
3. `/equity-decision 7203` でトヨタの memo が EDINET + Yahoo 経由で出る
4. データ取得失敗時、hallucination ではなく明示的に "数字取得失敗" を memo に書く
5. 末尾の「深掘りする？」5 件が表示される
6. SKILL.md 内に anthropics/financial-services への帰属表記
7. `dot_claude/skills/equity-decision/scripts/*.py` が `uv run` で単体実行できる
8. 簡易テスト: 既知 ticker 数件 (NVDA, AAPL, 7203, 9984) でフェッチャが JSON を返す

ETF (Phase C) は v1.1、polish (cache / エラー文言整備) は v1.2 で別 PR。

## ライセンスとリスク

- 元 repo (Apache 2.0) の DCF / comps / 3-statement / thesis-tracker / earnings-analysis のフレーム参照あり
- 各 `references/*.md` 冒頭で帰属表記:
  ```
  > Adapted from anthropics/financial-services (Apache License 2.0).
  > Modified for retail use without paid data sources.
  ```
- 個人利用かつ chezmoi 管理内のため `LICENSE` / `NOTICE` ファイル設置までは過剰、ヘッダー帰属で済ます
- 出力 memo は **投資助言ではない** ことを冒頭 1 行で明示
- 取得データを盲信せず、最終判断はユーザ自身

## Open questions (実装段階で判断)

- yfinance の API は時々壊れる → 代替に Stooq の CSV をフォールバックに入れるか (Phase D で検討)
- EDINET API は accessKey 不要だがレート制限あり → 同 API 1 ticker で複数取得時の throttle 設計
- Damodaran データは年次更新 → 何時の snapshot をデフォルトにするか (最新を毎年 1 回手動更新 or skill が自動 fetch)
