# Japanese Writing Norms

Canonical reference for natural, readable Japanese prose. Loaded just-in-time by the writing skills (`technical-writing`, `article-writing`, `japanese-ai-writing-proofreader`) and by injection hooks — never always-on. This file is the single source of truth for the norms below; skills apply them and cite this file rather than restating it.

## Audience

Fix the reader in one line before writing; never ask the user for a persona per document. Default reader: a general reader, not necessarily an engineer. When the artifact is explicitly a technical document (README, design doc, runbook, API doc), the default narrows to 一般的な日本のソフトウェアエンジニア. Genre-specific material (style profiles, reader-calibration tables) may override the default.

The vocabulary test is the reader: would they say the word aloud, and understand it on first hearing? Pick the word that passes — the settled Japanese term, カタカナ, or a plain paraphrase — over one that merely translates the English.

## Structure

Open with the conclusion — the sentence the reader came for — then supply background only where it changes what the reader does next. One register per document (だ・である or です・ます; pick from the target repo/media's existing convention, not per-sentence).

Before: 3 sentences of context before the procedure starts. After: the outcome first, procedure below it.

Form follows the information's structure, not the genre: parallel enumerable facts (3 項目以上, no logical connective between them) → bullet list; causal or argumentative flow（「だから」「しかし」で繋がる内容）→ prose; several subjects compared on the same attribute axis → table. A logical connective appearing inside a bullet is the signal to fall back to prose.

## Volume and shape (effort targets)

Initial values, not lint gates — exceeding one is a signal to cut, split, or switch form. Recalibrate them from writing-bench measurements (`tests/writing-bench/` in the dotfiles repo), not by debate.

| Unit      | Target                                                              |
| --------- | ------------------------------------------------------------------- |
| Sentence  | ≤ 60 字目安                                                          |
| Paragraph | ≤ 150 字, 2–4 sentences                                              |
| Section   | ≤ 400 字 — beyond that, split with a subheading or switch to a diagram |
| PR body   | ≤ 40 lines                                                           |

Shape: heading depth ≤ h3（h4 が要るなら文書分割のシグナル）; 3–7 sections per document; list nesting ≤ 2 levels（3 段目が要る構造は表か図）; conclusion first at section level too, not only document level; one document serves one purpose — split when it forks.

## Sourcing / faithfulness

Every load-bearing claim traces to a source: code, an official doc, or a measurement the writer ran. Verify what is verifiable before writing instead of hedging — `要確認` is for what is genuinely out of reach, not what is merely tedious. State a remaining inference as an inference（「〜と考えられる。要確認」), never as settled fact. Attach the source to the claim (`path:line`, a link, the command that produced a number) so a reader can re-check it without asking the writer.

## Rhythm (fingerprint axis)

Detectable post-hoc by a mechanical lint (sentence-length statistics, paragraph shape). Corpus-calibrated signal (137 human / 406 AI documents): rhythm, not vocabulary, is the strongest measured AI marker.

- Vary sentence length on purpose; a short sentence among long ones reads as human, uniform length reads as generated
- Don't give every paragraph the same shape (e.g. exactly 3–4 sentences each)
- Occasional 体言止め is a human marker (present in ~60% of human documents, near-absent in AI ones) — use it sparingly in formal technical writing, more freely in essays/blog prose
- Don't repeat the 「〜ではなく…」 antithesis pattern three or more times in one document; it reads as a template once it recurs

## Cognitive rhythm (structural axis)

A generation-time property, not a post-hoc lint target — no mechanical check can score it, so it has to be held in mind while writing.

The core diagnostic: does this sentence update the reader's situation, or only the document? A sentence that adds a fact, a decision, or a consequence the reader didn't have moves their understanding forward. A sentence that announces progress, describes its own structure, or hedges without substance（「以下で詳しく見ていく」「〜という点に注意が必要である」で終わるだけの文）updates nothing but the page. When cutting for length, cut the second kind first.

Beyond that diagnostic:

- Hold a question or an answer back deliberately, so the next paragraph has somewhere to go — resolving everything immediately flattens the reason to keep reading
- Alternate dense and sparse paragraphs rather than keeping every paragraph at the same information density
- Never name the device in the text itself. Writing "ここでは疑問を残したまま次に進む" describes the technique instead of using it, and the description is itself a document-updating sentence — the device only works while it stays invisible

Distilled from k16shikano's "cognitive-rhythm-writing" method (GitHub gist eb2929f13ed19c97188393d297be8432), restated in house style — not a verbatim copy.

## AI-smell taxonomy

Detectable post-hoc; the mechanical-lint safety net beneath the structural axis above. Reference: [textlint-rule-preset-ai-writing](https://github.com/textlint-ja/textlint-rule-preset-ai-writing).

- **Mechanical list templates**: a fixed `**label**: description` pattern forced onto every bullet, or emoji markers (✅❌💡🎯🚀) standing in for structure → use prose where prose works; drop the boilerplate label
- **Hype vocabulary**: 「革命的」「画期的」「世界初」「パラダイムシフト」「圧倒的」「究極の」「最強の」「次世代」 → replace with a concrete number, fact, or comparison
- **Over-emphasis**: bolded adverbs（`**非常に**`、`**極めて**`）, an emoji on every heading, repeated 「！」 → keep only the one emphasis that matters
- **English-style colon syntax**: `:` placed right after a clause ending in a verb/adjective（❌「実装した: 〜」）→ receive with a noun before the colon, or break into a separate sentence（✅「実装した内容は次のとおり: 〜」）
- **Translationese vocabulary（翻訳借用語）**: rare kanji compounds that exist only as literal translations of English terms（canonical → 正本・正典、mitigation → 緩和策の直訳連発）and fail the Audience vocabulary test → the settled Japanese term, カタカナ, or a plain paraphrase（「唯一の情報源」）. Each one caught in a real draft goes into the proofreader dictionary (`writing-proofread` skill, `assets/prh.yml`) so the next detection is deterministic
- **Particle omission and padding**: dropped 助詞（「ファイル作成」→「ファイルを作成する」), passive where active reads plainer（「〜される」→「〜する」）, and padding like 「〜することができる」→「〜できる」、「〜を行う」→ the verb itself
