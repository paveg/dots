# Fact-Check Procedure

Hallucination gate for article drafts. Every verifiable claim in the draft must
be traced to a primary source or removed. Run this as an independent phase
AFTER drafting — the writer's confirmation bias passes through if you verify
while writing.

## 1. Build the claims table

Extract every verifiable claim from the draft. A claim is verifiable if a
reader could prove it wrong. Categories to sweep:

| Category | Examples |
| :--- | :--- |
| 数値 | 価格、所要時間、行数、件数、割合、日付、期限 |
| 固有名詞 | 製品名・型番、サービス名、人名、組織名、地名 |
| バージョン・仕様 | ライブラリのバージョン、API名、コマンド名、フラグ、デフォルト値 |
| コード・コマンド | 掲載コードの動作、コマンド出力、エラーメッセージ |
| 引用・帰属 | 「Xは〜と述べている」、記事・論文・ドキュメントへの言及 |
| URL | 本文・脚注の全リンク |
| 因果・経緯 | 「AしたらBになった」という実体験の記述（素材ノートと突き合わせ） |

Format:

```markdown
| # | 主張 | 出典 | 検証方法 | 結果 |
| 1 | 合計69.3万円 | 領収書メモ (素材ノート#4) | grep '693,000' source.md | ✅ |
| 2 | 「半分以下(約42%)に短縮」 | #1,#3 から導出 | 365s/860s≈0.42 を計算 | ✅ 導出値 |
| 3 | etcd v3.5 がデフォルト | — | 未検証 | ❌ 要対応 |
```

- The 出典 column reuses 素材ノート entries — the 素材ノート is built at
  collection time, this table verifies the draft against it
- **導出値** (values computed from sourced numbers, like the 42% above) are
  legitimate: mark ✅ with the computation shown as the verification method
- Facts the user stated verbally belong in the 素材ノート too, sourced as
  「ユーザー談」— at this gate they are unverified until a primary source
  backs them (downgrade/flag candidates, not ✅)

## 2. Verify each claim against a primary source

Match the verification method to the claim type:

- **数値・固有名詞**: grep the source material (素材ノート, original repo,
  receipts, logs). Exact match including units and 税込/税抜.
- **コード・コマンド**: run it, or read the actual code in the referenced repo.
  Never publish a command output you did not capture.
- **バージョン・仕様**: check the official docs or the lockfile/changelog of
  the actual project. Training-data memory is not a source.
- **URL**: fetch every link. Confirm (a) it resolves, (b) the page actually
  supports the sentence that cites it.
- **引用・帰属**: locate the original passage. Paraphrases must not strengthen
  the original claim (「〜かもしれない」を「〜である」にしない).
- High-stakes claims (money, legal deadlines, health, other people's work):
  verify with a second independent source, or dispatch a skeptic subagent to
  refute the claim before trusting it.

## 3. Resolve failures

For each ❌, exactly one of:

1. **Fix** — correct the draft to match the source
2. **Downgrade** — rewrite as opinion/estimate（「実測で約〜だった」「〜と推定」）
   so it is no longer a falsifiable claim presented as fact
3. **Delete** — if the claim carries no weight, cut it
4. **Flag** — only for claims that genuinely require the user
   (実測値、金額の公開可否、所属組織に関わる記述).
   Mark in the draft as `<!-- 要確認: ... -->` and list them in the final report

「たぶん合っている」は選択肢にない。Unverified claims do not ship as facts.

## 4. Gate output

Present the completed claims table to the user with counts
(verified / fixed / downgraded / deleted / flagged). The draft does not proceed
to proofreading until the table has no unresolved ❌.
