---
name: japanese-ai-writing-proofreader
description: >-
  Proofread Japanese prose in three passes: textlint (mechanical), AI-smell
  removal, and deep naturalness (sentence-end variety, rhythm, connectives).
  Use when asked to 「校正して」「推敲して」「AI臭を消して」「自然な日本語にして」,
  when polishing article drafts / PR bodies / docs written in Japanese, or as
  the proofreading phase of the article-writing skill.
argument-hint: <file or text to proofread>
---

# Japanese AI-Writing Proofreader

Three passes, mechanical first. The textlint pass exists because deterministic
checks beat LLM judgment where both can do the job — run it before reading the
text yourself, so your review starts from machine-verified ground.

## Mode

- **report** (default for text the user wrote): list findings with before/after
  suggestions; change nothing
- **fix** (default for Claude-drafted text, or when the user asks for 修正):
  apply the fixes, then summarize what changed by category. When the target
  is a file, edit it in place AND show the corrected text (or the changed
  passages, for long files) in the response; when it is pasted text, return
  the corrected text in full (no config probe needed — go straight to the
  fallback)

When unclear which applies, ask.

## Scope guards

- Never touch code blocks, command output, quoted text (`>`), or verbatim
  excerpts — flag issues inside them at most
- **Voice preservation**: if the text has an intentional style (e.g.
  article-writing's style profiles — 括弧ツッコミ, 取り消し線, 「普通に」,
  casual fragments), those devices are NOT findings. Proofreading removes
  AI-smell, not personality. The protection covers the device itself, not
  errors inside it: real 誤字・誤用 inside a device are still findings;
  orthography preferences inside one are LOW at most. When invoked from
  article-writing, re-read the active style profile first.

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

The fallback covers, beyond the two base presets: 表記ゆれ via the bundled
`assets/prh.yml` dictionary (grow it when new variants surface in real
drafts), English term casing (`terminology`), 漢字→ひらがな for
形式名詞/副詞/補助動詞, and い抜き言葉 (`@textlint-ja/no-dropping-i`).

- The fallback handles `.md`/`.txt`. For `.mdx` without a project config, copy
  to a temp `.md` first
- For bare text (not a file), write it to a temp `.md` and lint that
- Treat findings as advisories, not auto-applied truth: judge each against the
  intended voice. The fallback config already disables
  `no-exclamation-question-mark` and `ja-no-weak-phrase` because 「？」 and
  「〜と思います」 are legitimate in this user's prose. Likewise, い抜き inside
  括弧ツッコミ can be intentional — judge before fixing
- Findings that contradict an explicit repo/media style rule (e.g.
  `no-mix-dearu-desumasu` firing on a だ・である規約の記事) are residual:
  leave them, and note the count as intentionally残置 in the summary
- An intentional passage that keeps tripping rules can be fenced with
  `<!-- textlint-disable [rule] -->` … `<!-- textlint-enable -->` (the
  `comments` filter). Use sparingly and prefer the narrow per-rule form —
  never weaken the config itself, and do not weaken a project's textlint
  config to make findings go away

## Pass 2: AI-smell (the 5 categories)

Aligned with `~/.claude/rules/japanese-writing.md`. Hunt each category
explicitly:

1. **機械的リスト**: `**ラベル**: 説明` templates, emoji markers (✅❌💡),
   identical structure forced onto every bullet → rewrite as prose or
   destructure the list
2. **誇張**: 「革命的」「劇的に」「圧倒的」「究極の」 → replace with the
   concrete number or comparison, or delete
3. **過剰な強調**: bolded adverbs, emoji-led headings, repeated 「！」 →
   keep at most the one emphasis that matters
4. **英語式コロン**: 述語直後の「:」（「実装した: 〜」）→ receive with a noun
   or split the sentence
5. **冗長・受動**: 「することができる」→「できる」、「〜を行う」→ verb form,
   passive → active, dropped particles restored（「設定変更」→「設定を変更する」）

This manual read is also where plain 誤字・誤用・文法ミス get caught — textlint
misses many（「とゆう」等）. Report them under Pass 2 in the findings table.

## Pass 3: Deep naturalness (what surface rules miss)

This is where text that passes Pass 1-2 still reads AI-written:

- **文末の単調**: same ending 3+ sentences in a row（です。です。です。）→
  rotate でした／ません／た。／体言止め／問いかけ
- **文長の均質**: equal-length sentences in a flat march → vary; place a short
  punch sentence after a long explanation
- **接続詞の機械的連結**: paragraph after paragraph opening with
  「また」「さらに」「次に」 → cut (juxtaposition often suffices) or vary
  （ただ／そこで／つまり／一方で）
- **段落の均質**: every paragraph the same size → merge or split by content
- **読点過多/過少**: 一文に読点4つ以上は分割を検討。読点ゼロの長文は補う
- **情報の出し順**: conclusion buried at paragraph end, examples before the
  point they illustrate → lead with the load-bearing sentence
- **翻訳調**: 「〜することによって」「〜という形で」「〜の方(ほう)」の多用 →
  直接的な構文に組み替える

## Output

Findings table (report mode) or applied-fix summary (fix mode):

```markdown
| Pass | 重要度 | 箇所 | Before → After |
```

- 重要度: CRITICAL（意味が壊れている・事実が変わる）/ IMPORTANT（誤字・誤用・
  文法ミス、および明確なAI臭）/ LOW（表記の好み）。Present CRITICAL and
  IMPORTANT in the table. LOW: one aggregate line — count plus rule/kind names
  only（「ほか LOW 2件（訳→わけ等の表記）」), no Before→After. This keeps
  Pass 1 evidence visible without itemizing
- In fix mode, end with counts grouped by pass（textlint / AI臭 / 自然さ）and
  anything intentionally left alone (voice devices, quoted text)
