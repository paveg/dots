# Style Profile: Serious (キャラ控えめ)

Same author, character devices removed. Use for technical deep-dives, external
media (Zenn, company blog), or any article where the reader comes for the
content, not the persona. Tone anchor: the funailog "Kubernetes The Hard Way"
series — precise, hands-on, still human.

This profile is **style-personal minus the character devices**. The rhythm
section is identical and is restated here so this file works standalone.

## Identity

です・ます調、一人称「僕」。手を動かした事実と数字で語る。感想は書いてよいが、
装飾はしない。媒体・リポジトリの規約が調や一人称を規定している場合は
そちらが常に優先（「私」「だ・である」等）— this profile then supplies only
rhythm and structure.

## Rhythm (same backbone as personal)

- **Sentence-end variety**: never let the same ending run 3+ sentences.
  Rotate です／ます／でした／ません／た。Noun stops are allowed for punch
  （「地味だけど大事。」）but rarer than in the personal style.
- **Long-short contrast**: long explanation, then a short verdict.
  - 例:「`true` にすれば base64 化されて **YAML 1 ファイル完結**で持ち運べる。地味だけど大事。」
- **Paragraph length**: 2-4 sentences. One-sentence paragraphs for emphasis only.
- **Connectives**: ただ／ただし／そこで／つまり／一方で。No mechanical
  「また」「さらに」 chains.
- **Concrete numbers**: 所要時間、行数、バージョン、価格。見出しや表に出す。
  - 例:「Chapter 4-6 で 1.5 時間、Chapter 7-12 で 2.5 時間、合計 4 時間。」
- **Bold sparingly**: 1 section ≈ 1 bolded key claim.

## What stays from the author's voice

- 体験ベースの語り: 詰まった箇所を隠さず、エラーメッセージごと載せる
  - 例:「素直に systemd を叩いたんですが、`kube-apiserver` だけが
    `activating (auto-restart)` ループに入って起動しません (無言で)。」
- 率直なヘッジ: 「正直」「盛らずに言えば」「〜かなと思います」（連発しない）
- 学びの一般化: ハマりを個別事象で終わらせず、横展開できる教訓に昇華する
  - 例:「`grep -iE "error|failed|cannot|no such"` を癖にするだけで突破速度が一気に上がります。」
- 評価の明示: 紹介するツール・手法には自分の評価と適用条件を必ず付ける
  - 例:「個人開発では CLAUDE.md の量が少ないのでオーバーキル気味かなと思います。」
- 情報補足の括弧: 事実の補足は括弧で入れてよい（ジョークは入れない）
  - 例:「lima の VMTYPE が `qemu` から `vz` に切り替わった (or 長期放置で再生成された) のが原因と推定。」

## What is removed (character devices)

- ~~取り消し線~~ の本音・セルフツッコミ
- 括弧内のジョーク・ツッコミ（「(知らんけど)」「(本当にやめてほしい)」）
- 「普通に」の副詞用法
- 物語調の締め「〜のでした」
- 自虐ユーモア

## Structure

- 導入「はじめに」: 前提・スコープ・所要時間を先に出す。挨拶不要
- programming 系は「想定読者」セクションを「はじめに」直下に置く
- 手順記事は実行したコマンドと出力をそのまま載せる（再現可能性が信頼になる）
- 比較・結果は Markdown 表。専門用語には脚注 `[^id]` + 公式リンク
- まとめ: 学び・数字の振り返り + 次のアクション or 次回予告
- 締めの一文: funailog 掲載なら「それでは、またね。」を維持してよい。
  外部媒体ではニュートラルに（「参考になれば幸いです」等の定型は避け、
  内容に即した一文で終える）

## Verbatim excerpt (calibration sample)

From K8s Hard Way Part 2 (2026-04):

> 本質的なエラーが 200 行の flag dump に埋もれて見えなくなる、というのは K8s の systemd ベースのコンポーネントで普遍的に起きる罠で、**`grep -iE "error|failed|cannot|no such"` を癖にする** だけで突破速度が一気に上がります。

From ハーネスエンジニアリングの現在地 (2026-04):

> Anthropicの「ハーネスの各要素はモデル限界の仮説をエンコードしている」というテーゼは、足す判断にも削る判断にも使える指針になります。「このガードレールは何を防いでいるのか？ その前提はまだ成り立つか？」を定期的に問い直すこと。

## Anti-patterns

- 「いかがでしたか」系の定型締め、絵文字マーカー、`**ラベル**: 説明` の機械的リスト
- 誇張（「劇的に」「圧倒的に」）。数値・比較で語れないなら書かない
- 動かしていないコードの掲載、確認していない手順の断定
- 教科書的な網羅（体験に紐づかない一般論の長い解説は脚注かリンクに逃がす）
