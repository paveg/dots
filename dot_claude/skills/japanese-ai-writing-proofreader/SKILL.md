---
name: japanese-ai-writing-proofreader
description: >-
  Proofread Japanese prose in four passes: textlint (mechanical), a rhythm/statistics lint (sentence-length burstiness, paragraph uniformity, antithesis repetition), AI-smell removal, and deep naturalness (sentence-end variety, connectives). Use when asked to 「校正して」「推敲して」「AI臭を消して」 「自然な日本語にして」, when polishing article drafts / PR bodies / docs written in Japanese, or as the proofreading phase of the article-writing skill.

argument-hint: <file or text to proofread>
---

# Japanese AI-Writing Proofreader

Four passes, mechanical first. The textlint and rhythm-lint passes exist because deterministic checks beat LLM judgment where both can do the job — run them before reading the text yourself, so your review starts from machine-verified ground.

## Mode

- **report** (default for text the user wrote): list findings with before/after suggestions; change nothing
- **fix** (default for Claude-drafted text, or when the user asks for 修正): apply the fixes, then summarize what changed by category. When the target is a file, edit it in place AND show the corrected text (or the changed passages, for long files) in the response; when it is pasted text, return the corrected text in full (no config probe needed — go straight to the fallback)

When unclear which applies, ask.

## Scope guards

- Never touch code blocks, command output, quoted text (`>`), or verbatim excerpts — flag issues inside them at most
- **Voice preservation**: if the text has an intentional style (e.g. article-writing's style profiles — 括弧ツッコミ, 取り消し線, 「普通に」, casual fragments), those devices are NOT findings. Proofreading removes AI-smell, not personality. The protection covers the device itself, not errors inside it: real 誤字・誤用 inside a device are still findings; orthography preferences inside one are LOW at most. When invoked from article-writing, re-read the active style profile first.

## Pass 1: textlint (mechanical)

Prefer the project's own setup when it exists:

```bash
# look for config in the target file's directory and its repo root, not your cwd
ls <target-dir>/.textlintrc* 2>/dev/null
npx textlint --format compact <file>            # or the repo's lint script
```

Otherwise run the bundled fallback config (no project pollution):

```bash
npx -y -p textlint \
  -p textlint-rule-preset-ja-technical-writing \
  -p @textlint-ja/textlint-rule-preset-ai-writing \
  -p textlint-rule-prh \
  -p textlint-rule-terminology \
  -p textlint-rule-ja-hiragana-keishikimeishi \
  -p textlint-rule-ja-hiragana-fukushi \
  -p textlint-rule-ja-hiragana-hojodoushi \
  -p @textlint-ja/textlint-rule-no-dropping-i \
  -p textlint-filter-rule-comments \
  textlint --config ~/.claude/skills/japanese-ai-writing-proofreader/assets/textlintrc.json \
  --format compact <file>
```

The fallback covers, beyond the two base presets: 表記ゆれ via the bundled `assets/prh.yml` dictionary (grow it when new variants surface in real drafts), English term casing (`terminology`), 漢字→ひらがな for 形式名詞/副詞/補助動詞, and い抜き言葉 (`@textlint-ja/no-dropping-i`).

- The fallback handles `.md`/`.txt`. For `.mdx` without a project config, copy to a temp `.md` first
- For bare text (not a file), write it to a temp `.md` and lint that
- Treat findings as advisories, not auto-applied truth: judge each against the intended voice. The fallback config already disables `no-exclamation-question-mark` and `ja-no-weak-phrase` because 「？」 and 「〜と思います」 are legitimate in this user's prose. Likewise, い抜き inside 括弧ツッコミ can be intentional — judge before fixing
- Findings that contradict an explicit repo/media style rule (e.g. `no-mix-dearu-desumasu` firing on a だ・である規約の記事) are residual: leave them, and note the count as intentionally残置 in the summary
- An intentional passage that keeps tripping rules can be fenced with `<!-- textlint-disable [rule] -->` … `<!-- textlint-enable -->` (the `comments` filter). Use sparingly and prefer the narrow per-rule form — never weaken the config itself, and do not weaken a project's textlint config to make findings go away

## Pass 2: rhythm & statistics lint

Covers what textlint structurally cannot: sentence-length homogeneity (burstiness), paragraph-shape uniformity, zero 体言止め rate, negation→affirmation antithesis repetition（「〜ではなく…」）, morphology-based translationese, n-gram repetition, and lexical diversity. Thresholds are corpus-calibrated (137 human / 406 AI documents). Vendored from coji/natural-japanese — see `scripts/NOTICE.md`.

```bash
uv run ~/.claude/skills/japanese-ai-writing-proofreader/scripts/lint.py --json <file>
```

Add `--genre essay|tech|business` when the genre is clear — it switches to calibrated per-genre thresholds and reduces false positives. Dependencies (sudachipy) resolve automatically via PEP 723 inline metadata; no venv setup needed.

- Findings are suspicions, not orders — apply the same 直す / 残す（理由） discipline as Pass 1
- Exit code is 0 regardless of finding count (this is a lint, not a gate); 1 only on input errors
- In fix mode, after applying fixes, re-run passing the previous JSON via `--baseline <prev.json>` — it classifies findings as resolved / new / persisting. Repeat until no new findings appear, then delete the intermediate JSON files
- If `uv` is unavailable, skip this pass; Pass 4's manual checks are the fallback

## Pass 3: AI-smell (the 5 categories)

Full taxonomy: `~/.claude/references/japanese-writing/norms.md`. Hunt each category explicitly: mechanical list templates, hype vocabulary, over-emphasis, English-style colon syntax, and particle omission / padding (dropped 助詞, passive → active,「することができる」→「できる」等).

This manual read is also where plain 誤字・誤用・文法ミス get caught — textlint misses many（「とゆう」等）. Report them under Pass 3 in the findings table.

## Pass 4: Deep naturalness (what surface rules miss)

This is where text that passes Pass 1-3 still reads AI-written. The dimensions Pass 2 now catches mechanically (文長の均質, 段落の均質, 接続詞の機械的連結, 翻訳調) are dropped from this list — this pass covers only what remains judgment-dependent. The structure and cognitive-rhythm principles behind these checks live in `~/.claude/references/japanese-writing/norms.md`; this pass is where a human read verifies the draft actually holds them:

- **文末の単調**: same ending 3+ sentences in a row（です。です。です。）→ rotate でした／ません／た。／体言止め／問いかけ
- **読点過多/過少**: 一文に読点4つ以上は分割を検討。読点ゼロの長文は補う
- **情報の出し順**: conclusion buried at paragraph end, examples before the point they illustrate → lead with the load-bearing sentence (norms' Structure principle)
- **状況を更新しない文**: progress announcements, self-description, or unsubstantiated hedges that add nothing the reader didn't already have → cut or replace with a claim that moves the reader's understanding forward (norms' Cognitive rhythm principle)
- **未消化の専門用語・カタカナ英語**: English or loanword jargon a general reader stumbles on → replace with settled Japanese, or gloss on first use（ドロップ→配線・ケーブル、ネゴシエーション→つながる・リンクする、ラジオ→帯域、律速→ボトルネック・頭打ち、Traffic Rule→トラフィックルール）. Keep field-standard terms as-is（API・PoE・VLAN・SSID）. textlint cannot catch this — read for it manually
- **初出の専門用語の導入**: don't start using a term in the body before its alias/definition appears — a VLAN labeled Default in a table, then called Trusted in prose with no bridge, reads as 唐突 → introduce on first use as「A（＝B、その役割）」

## Output

Findings table (report mode) or applied-fix summary (fix mode):

```markdown
| Pass | 重要度 | 箇所 | Before → After |
```

- 重要度: CRITICAL（意味が壊れている・事実が変わる）/ IMPORTANT（誤字・誤用・文法ミス、および明確なAI臭）/ LOW（表記の好み）。Present CRITICAL and IMPORTANT in the table. LOW: one aggregate line — count plus rule/kind names only（「ほか LOW 2件（訳→わけ等の表記）」), no Before→After. This keeps Pass 1 evidence visible without itemizing
- In fix mode, end with counts grouped by pass（textlint / リズム・統計 / AI臭 / 自然さ）and anything intentionally left alone (voice devices, quoted text)
