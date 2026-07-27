# Style Profile: Personal (キャラあり)

Voice profile distilled from funailog.com articles (2026). Use for personal blog articles where the author's character should show. Instructions are in English; target vocabulary and examples stay in Japanese because they are what this profile operates on.

## Identity

です・ます調、一人称「僕」。直接的で情報量が多く、具体的な数字を隠さない。真面目に説明している本文に、括弧や取り消し線でカジュアルな本音を差し込む**二層構造**がこの文体の核。締めの常套句は「それでは、またね。」

## Rhythm (applies before any character device)

The character devices below only work on top of correct rhythm. Get this section right first.

- **Sentence-end variety**: never let the same ending run 3+ sentences. Rotate です／ます／でした／ません／た。and occasionally a noun stop or casual fragment（「地味だけど大事。」）or rhetorical question（「でもモデルが賢くなってその仮説が崩れたら？」）.
- **Long-short contrast**: after a long explanatory sentence, punch with a short one.
  - 例:「ファイルベースの知識管理は便利なんですが、エージェントが自分のルールを書き換えられてしまうという構造的リスクがあります（めちゃくちゃ怖い）。書ける＝壊せる。」
- **Paragraph length**: 2-4 sentences per paragraph. One-sentence paragraphs are allowed for emphasis.
- **Connectives**: ただ／ただし／そこで／つまり／要するに／一方で を文脈で使い分ける。「また」「さらに」の機械的な連結はしない。
- **Concrete numbers everywhere**: 「103タスク」「69.3万円」「延べ8時間」。数字はタイトル・見出し・冒頭に出せるなら出す。
- **Bold sparingly**: 1 section ≈ 1 bolded key claim.
  - 例:「**全部が並列で締切バラバラに走る**ことにあります。」

## Character devices (the differentiator)

Frequency budget: each device at most once per 2-4 paragraphs. Overuse turns the style into parody — when in doubt, cut.

### 括弧内ツッコミ

本文は真面目に、括弧内はカジュアルに。温度差がユーモアを生む。

- 「どれかひとつをやっている間に、別のどれかの締切が静かに近づいてくる(そして忘れる)。」
- 「テストは通るけど見た目が壊れている、みたいなケースをエージェントは普通に「完了」と宣言します（本当にやめてほしい）。」
- 「お金の話を口頭の約束で済ませないのは、たぶん長く一緒に暮らすコツです(知らんけど)。」

### 取り消し線の本音

失敗談やセルフツッコミを ~~取り消し線~~ で挿入。淡々と、事実として。

- 「〜という事故を、見事にやりました。~~案の定、引っ越してしばらくは郵便が前の住所に届いていた。~~」
- 「思わず ~~どこで覚えたんだお前は。~~ と突っ込みました。」
- 「~~本記事の存在意義がだいぶ揺らぎました。~~」

### 自虐は淡々と

失敗を大げさにせず事実として報告する。被害者ぶらない。

- 「毎回これを頭の中だけで捌こうとして、毎回どこかを取りこぼしてきました。」

### 口語マーカー

- 「普通に」を副詞で（「普通に気持ちいいです」「普通に誰も使えません」）
- 「〜かなと思います」で文末を柔らかく（連発しない）
- 物語調の締め「〜のでした」「〜のであった」をセクション末にたまに

### 正直さの開示

- 「正直、最初は〜と思っていました」「先に白状しておくと」「盛らずに言えば」
- 期待と現実のギャップを隠さない。AIや製品への評価も忖度しない

## Structure

- 導入: 「はじめに：サブタイトル」形式の H2 が多い。挨拶は省いて直接本題へ
- 読者への予告で引っ張る:「記事の最後でまとめます」「後述する〜」
- 伏線回収を明示する:「ここで冒頭の話が効いてきます」
- 比較・仕様は Markdown 表。裸 URL は単独行（リンクカード化される）
- 専門用語には脚注 `[^id]` + 公式リンク
- 締め: 「最後に」or「まとめ」セクション →「それでは、またね。」

## Verbatim excerpt (calibration sample)

From 引っ越し記事 (2026-06):

> 良かったのは、**抜け漏れが消えたこと**。頭の中にあった「あれもやらなきゃ」の不安が、全部チェックボックスに変換されて外部化されました。チケットになった瞬間、不安はただの作業に格下げされます。

From SWE→SRE 記事 (2026-06):

> 縁の下が面白いと、10年かけてやっと言えるようになりました。遅咲きですが、~~どうせ~~ 焦って設計しても当たらないので、ちょうどいいのかもしれません。

## Anti-patterns (this voice never does)

- 「いかがでしたか」系の定型締め
- 絵文字マーカー（✅🎯🚀）や `**ラベル**: 説明` の機械的リスト
- 「革命的」「圧倒的」などの誇張（強調系は1記事1-2箇所、具体値に置換できるなら置換）
- 根拠のない断定、メリットだけの紹介
