# Fact-Check Procedure

Hallucination gate for article drafts.
Every verifiable claim in the draft must be traced to a primary source or removed.
Run this as an independent phase AFTER drafting — the writer's confirmation bias passes through if you verify while writing.

## 1. Build the claims table

Extract every verifiable claim from the draft.
A claim is verifiable if a reader could prove it wrong.
Categories to sweep:

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

- The 出典 column reuses 素材ノート entries — the 素材ノート is built at collection time, this table verifies the draft against it
- **導出値** (values computed from sourced numbers, like the 42% above) are legitimate: mark ✅ with the computation shown as the verification method
- Facts the user stated verbally belong in the 素材ノート too, sourced as 「ユーザー談」— at this gate they are unverified until a primary source backs them (downgrade/flag candidates, not ✅)

## 2. Verify each claim against a primary source

Match the verification method to the claim type:

- **数値・固有名詞**: grep the source material (素材ノート, original repo, receipts, logs).
  Exact match including units and 税込/税抜.
- **コード・コマンド**: run it, or read the actual code in the referenced repo.
  Never publish a command output you did not capture.
- **バージョン・仕様**: check the official docs or the lockfile/changelog of the actual project.
  Training-data memory is not a source.
- **URL**: fetch every link.
  Confirm (a) it resolves, (b) the page actually supports the sentence that cites it.
- **引用・帰属**: locate the original passage.
  Paraphrases must not strengthen the original claim (「〜かもしれない」を「〜である」にしない).
- High-stakes claims (money, legal deadlines, health, other people's work): verify with a second independent source, or dispatch a skeptic subagent to refute the claim before trusting it.

## 3. Resolve failures

For each ❌, exactly one of:

1. **Fix** — correct the draft to match the source
2. **Downgrade** — rewrite as opinion/estimate（「実測で約〜だった」「〜と推定」）so it is no longer a falsifiable claim presented as fact
3. **Delete** — if the claim carries no weight, cut it
4. **Flag** — only for claims that genuinely require the user (実測値、金額の公開可否、所属組織に関わる記述).
   Mark in the draft as `<!-- 要確認: ... -->` and list them in the final report

「たぶん合っている」は選択肢にない。
Unverified claims do not ship as facts.

## 4. Gate output

Present the completed claims table to the user with counts (verified / fixed / downgraded / deleted / flagged).
The draft does not proceed to proofreading until the table has no unresolved ❌.

## 5. 公開可否スイープ（自宅インフラ・アカウントを扱う記事）

ファクトチェックが「その記述は正しいか」なら、これは「その記述を公開してよいか」。
自宅ネットワーク・自宅サーバ・スマートホーム・個人アカウントを書く記事に適用する。
一般的な技術解説の記事でも、自宅の実設定・実アカウントに触れる箇所が1つでもあれば、その箇所だけ掃引する。

**判別の原則**: ブログ上の人格と、物理環境・実アカウント・物理的な居場所を結びつける識別子は、ブロードキャスト済み・既出でも伏せる。
汎用的なブランド名・製品名は効果と労力で判断する（普及品を機械的に伏せない）。
ただし物理セキュリティに直結するブランド（スマートロック等）は、普及品でも慎重側に倒す。

スキャン対象と対応（本文テキストが対象。画像内の写り込みは §末尾の使い分けを参照）:

| 対象 | 例 | 対応 |
| :--- | :--- | :--- |
| 認証情報 | パスフレーズ、実APIキー、トークン | 削除。明らかなダミー（`YOUR_API_KEY`・伏字済み）は対象外 |
| SSID・ネットワーク名 | 実SSID名、SSID×セキュリティ方式の対応表 | プレースホルダに置換（例: 実名→`home`）。最弱SSIDを実名で名指ししない |
| アドレス（論理） | 公開IP、グローバルIPv6の実値、MAC/BSSID | 削除、または `<公開IP>` 等に置換。内部サブネット（RFC1918: `10.x` / `172.16–31.x` / `192.168.x`）は低リスク・許容 |
| 物理的な居場所（本文） | 住所、地名 | 物理セキュリティ上いちばん重い。削除・ぼかす。画像側（表札・窓外の風景・GPS）は下の Flag へ |
| アカウント・所属 | 実名、メール、SNSハンドル、勤務先 | 著者本人の署名・公開プロフィールは対象外。第三者や非公開の所属は削除、判断が要れば Flag |
| ホスト名・機器の識別子 | `Hub-Sesame` 等の識別子、シリアル | 本文にあれば置換（例: `<hostname>`）。ブランドは物理セキュリティの手がかり（スマートロック等は特に慎重に） |

- **置換 / 削除 / Flag の使い分け**: 本文テキストは置換か削除で直す。校正で完結しないものは本文に `<!-- 要確認: ... -->` を置き、最終レポートに列挙して人に委ねる。校正エージェントは画像の中身を判定・修正できない前提なので、**スクショを参照している箇所は、写り込みの有無を問わず一律 Flag**（表札・窓外の風景・GPS・機器の識別子などを人が確認・トリミング）。コーパス横断確認も Flag に回す
- **横断確認**: 過去記事のコーパスがある場合のみ、伏せると決めた識別子が別記事で既出でないか確認する。既出でも、人格↔物理を結ぶ識別子（実SSID 等）なら新記事では伏せて拡散を止める。汎用ブランドが既に方々へ出ているだけなら追わない
