---
name: writing-proofread
description: >-
  Proofread Japanese prose for AI smell, rhythm, and naturalness. Invoke only on an explicit user request — 「校正して」「推敲して」「AI臭を消して」「自然な日本語にして」 — or as the proofreading phase of the writing skill's article mode. Never fire proactively on PR bodies, commit messages, or docs you just wrote: the always-loaded japanese-writing rules already hold that baseline.

argument-hint: <file or text to proofread>
---

# Japanese AI-Writing Proofreader

Four passes, mechanical first. The textlint and rhythm-lint passes exist because deterministic checks beat LLM judgment where both can do the job — run them before reading the text yourself, so your review starts from machine-verified ground.

## Scale

Scale by size, not artifact type. Short utilitarian prose — commit messages, changelog entries, a few-line PR body or README tweak — gets Pass 1 and Pass 3 only: Pass 2's statistics are calibrated on full documents and mean nothing at that size, and a few lines leave Pass 4 nothing to check. But a long PR/issue body (目安: 40 行超, or more than one heading) is document-sized — run the full pipeline on it; routing PR bodies around Pass 4 (情報の出し順, buried conclusions, 整合性) by artifact type is what let 「読みづらい」 re-requests through minutes after a clean proofread. Articles and standalone documents get all four passes regardless of length. When in doubt, run the full pipeline.

## Mode

- **report** (default for text the user wrote): list findings with before/after suggestions; change nothing
- **fix** (default for Claude-drafted text, or when the user asks for 修正): apply the fixes, then summarize what changed by category. When the target is a file, edit it in place AND show the corrected text (or the changed passages, for long files) in the response; when it is pasted text, return the corrected text in full (no project-config probe needed — go straight to Pass 1's bundled fallback config)

When unclear which applies, ask.

## Scope guards

- Never touch code blocks, command output, quoted text (`>`), or verbatim excerpts — flag issues inside them at most
- Table data cells are near-verbatim: fix plain 誤字 inside them, nothing more. Prose crammed into cells is a structural finding (see below), not a rewrite target
- When invoked on a diff or with named target sections, touch only those parts — the surrounding existing text is context, not a target. Callers don't need to restate this in arguments
- **Structure is a finding, not a rewrite target**: when the dominant problems are structural — prose stuffed into table cells, a document far longer than its content, buried conclusions, a flow that wants a diagram — report them and recommend running the writing skill's technical mode (構成・文量・図示 live there) instead of polishing sentences harder. A clean sentence-level pass does not make a structurally unreadable document readable
- **Say only what the source says**: a replacement may use only information already present in the text. Cutting padding is the job; replacing 「継続的な改善」 with 「値のチューニング」, or a vague plan with a specific one the draft never stated, invents commitments on the author's behalf
- **Tone down the author's stance, don't delete it**: 「非常に大きな成果であると考えております」 is hype wrapped around a real evaluation. Reduce it to 「大きな成果だと考えています」 — same claim, less ceremony. The replacement must not smuggle in a new premise either（「想定した効果が出ました」 would assert a prior expectation the text never stated）. Deleting the sentence removes the author's judgment, which is theirs to make; delete only when nothing survives the padding
- **Voice preservation**: if the text has an intentional style (e.g. the writing skill's style profiles — 括弧ツッコミ, 取り消し線, 「普通に」, casual fragments), those devices are NOT findings. Proofreading removes AI-smell, not personality. The protection covers the device itself, not errors inside it: real 誤字・誤用 inside a device are still findings; orthography preferences inside one are LOW at most. When the caller has an active style profile (e.g. invoked from the writing skill's article mode), read that profile before judging anything as a finding.

## Pass 1: textlint (mechanical)

Prefer the project's own setup when it exists:

```bash
# config may sit beside the target file or at its repo root — not in your cwd
root=$(git -C <target-dir> rev-parse --show-toplevel 2>/dev/null)
find <target-dir> ${root:+"$root"} -maxdepth 1 -name '.textlintrc*'   # not `ls glob*` — zsh aborts the line when nothing matches
npx --loglevel=error textlint --format compact <file>   # or the repo's lint script
```

Otherwise run the bundled fallback config (no project pollution):

```bash
npx --loglevel=error -y -p textlint \
  -p textlint-rule-preset-ja-technical-writing \
  -p @textlint-ja/textlint-rule-preset-ai-writing \
  -p textlint-rule-prh \
  -p textlint-rule-terminology \
  -p textlint-rule-ja-hiragana-keishikimeishi \
  -p textlint-rule-ja-hiragana-fukushi \
  -p textlint-rule-ja-hiragana-hojodoushi \
  -p @textlint-ja/textlint-rule-no-dropping-i \
  -p textlint-filter-rule-comments \
  textlint --config ~/.claude/skills/writing-proofread/assets/textlintrc.json \
  --format compact <file>
```

The fallback covers, beyond the two base presets: 表記ゆれ via the bundled `assets/prh.yml` dictionary (grow it when new variants surface in real drafts), English term casing (`terminology`), 漢字→ひらがな for 形式名詞/副詞/補助動詞, and い抜き言葉 (`@textlint-ja/no-dropping-i`).

- `--loglevel=error` drops npm's own chatter, which otherwise outweighs the findings and has pushed the summary line out of view. Real failures (`E404`) still print. Never substitute `--silent`: it hides genuine errors too, so a failed lint looks identical to a clean one
- The fallback handles `.md`/`.txt`. For `.mdx` without a project config, copy to a temp `.md` first
- For bare text (not a file), write it to a temp `.md` and lint that
- Treat findings as advisories, not auto-applied truth: judge each against the intended voice. The fallback config already disables `no-exclamation-question-mark` and `ja-no-weak-phrase` because 「？」 and 「〜と思います」 are legitimate in this user's prose. Likewise, い抜き inside 括弧ツッコミ can be intentional — judge before fixing
- Orthography rules (`prh`, `terminology`) encode a house preference, not a correctness bar. Fire them only where the document is actually inconsistent with itself. A draft that writes サーバ in all three places has no 表記ゆれ to fix; rewriting it to サーバー corrects nothing and overwrites the author's spelling
- Findings that contradict an explicit repo/media style rule (e.g. `no-mix-dearu-desumasu` firing on a だ・である規約の記事) are residual: leave them, and note the count as intentionally残置 in the summary
- In fix mode, re-run this pass once after applying fixes. Exit code `0` means clean — stop there. If you intentionally left findings (orthography guard, 残置), the exit stays `1`: confirm the remaining count matches what you left instead of re-reading every finding. The exit-code shortcut works only because every rule in the bundled config resolves to error severity (enabled as bare `true` or an options object without `severity`); a rule added with `severity: warning` would exit `0` with findings and break the check silently — don't add one
- An intentional passage that keeps tripping rules can be fenced with `<!-- textlint-disable [rule] -->` … `<!-- textlint-enable -->` (the `comments` filter). Use sparingly and prefer the narrow per-rule form — never weaken the config itself, and do not weaken a project's textlint config to make findings go away

## Pass 2: rhythm & statistics lint

Covers what textlint structurally cannot: sentence-length homogeneity (burstiness), paragraph-shape uniformity, zero 体言止め rate, negation→affirmation antithesis repetition（「〜ではなく…」）, morphology-based translationese, n-gram repetition, and lexical diversity. Thresholds are corpus-calibrated (137 human / 406 AI documents). Vendored from coji/natural-japanese — see `scripts/NOTICE.md`.

Write the JSON to a file and read back only the actionable rows — the raw JSON runs 2–3× the size of the document, and `info` rows belong in the LOW aggregate line rather than your working set. Run the block as one shell invocation: `TMP` is shell state and does not survive into a later call.

```bash
LINT=~/.claude/skills/writing-proofread/scripts/lint.py
TMP=$(mktemp -d)   # unique dir — a fixed filename collides with other runs sharing a directory
VIEW='"検出\(.findings|length)件（うち info \([.findings[]|select(.severity=="info")]|length)件は LOW 集約）",
      (.findings[] | select(.severity != "info")
       | "L\(.line) [\(.severity)]\(if .status then " "+.status else "" end) \(.category): \(.excerpt) — \(.detail)")'

uv run $LINT --json <file> > $TMP/lint-1.json
jq -r "$VIEW" $TMP/lint-1.json
echo "$TMP"   # the fix-mode baseline re-run needs this path literally
```

Add `--genre essay|tech|business` when the genre is clear — it switches to calibrated per-genre thresholds and reduces false positives. Dependencies (sudachipy) resolve automatically via PEP 723 inline metadata; no venv setup needed.

- Findings are suspicions, not orders — apply the same 直す / 残す（理由） discipline as Pass 1
- Exit code is 0 regardless of finding count (this is a lint, not a gate); 1 only on input errors
- Open `$TMP/lint-1.json` directly only when one finding needs its `related_lines`; the jq view is the working set. If an excerpt doesn't match the document you're proofreading, you read another run's output — check the JSON's `.file` field
- The script's `severity` and this skill's 重要度 are separate scales that happen to share a word. Map by the Output section's definitions: a script `critical` is normally IMPORTANT here (it marks a pattern, not broken meaning); a `warn` is IMPORTANT when it points at a specific passage and LOW when it reports a whole-document statistic such as burstiness; `info` goes to the LOW aggregate line
- In fix mode, after applying fixes, re-run **this pass** once with `--baseline <dir>/lint-1.json`, writing to `<dir>/lint-2.json` — `<dir>` is the literal path the first run echoed. The re-run is a new shell call, so `TMP` no longer exists（an unexpanded `$TMP/` writes to the filesystem root）; re-declare `LINT` and `VIEW` in the same invocation. The jq view shows the `new` and `persisting` rows; resolved items move out of `.findings` into `.baseline`, so read their count separately: `jq -r '.baseline.summary | "resolved \(.resolved) / new \(.new) / persisting \(.persisting)"' $TMP/lint-2.json`. Report what persists with your reason for leaving it rather than starting another round, then delete the JSONs with plain `rm "$TMP"/lint-*.json`（`rm -rf` は環境によって hook に拒否される）
- If `uv` is unavailable, skip this pass; Pass 4's manual checks are the fallback
- If `jq` is unavailable, drop `--json` and the redirect and run the script bare — the human-readable format carries the same findings at roughly 3× the size of the jq view

## Pass 3: AI-smell (the 5 categories)

Read `~/.claude/references/japanese-writing/norms.md` here, once — Pass 4 works from the same read, so don't return to it. Then hunt each of its six categories explicitly: mechanical list templates, hype vocabulary, over-emphasis, English-style colon syntax, translationese vocabulary（翻訳借用語 — words failing the norms' Audience test; unambiguous ones also feed `assets/prh.yml`）, and particle omission / padding (dropped 助詞, passive → active,「することができる」→「できる」等).

This manual read is also where plain 誤字・誤用・文法ミス get caught — textlint misses many（「とゆう」等）. Report them under Pass 3 in the findings table.

## Pass 4: Deep naturalness (what surface rules miss)

This is where text that passes Pass 1-3 still reads AI-written. The dimensions Pass 2 now catches mechanically (文長の均質, 段落の均質, 接続詞の機械的連結, 翻訳調) are dropped from this list — this pass covers only what remains judgment-dependent. The structure and cognitive-rhythm principles behind these checks are the norms' own; this pass is where a human read verifies the draft actually holds them:

- **文末の単調**: same ending 3+ sentences in a row（です。です。です。）→ rotate でした／ません／た。／体言止め／問いかけ
- **読点過多/過少**: 一文に読点4つ以上は分割を検討。読点ゼロの長文は補う
- **情報の出し順**: conclusion buried at paragraph end, examples before the point they illustrate → lead with the load-bearing sentence (norms' Structure principle)
- **状況を更新しない文**: progress announcements, self-description, or unsubstantiated hedges that add nothing the reader didn't already have → cut or replace with a claim that moves the reader's understanding forward (norms' Cognitive rhythm principle)
- **未消化の専門用語・カタカナ英語**: English or loanword jargon a general reader stumbles on → replace with settled Japanese, or gloss on first use（ドロップ→配線・ケーブル、ネゴシエーション→つながる・リンクする、ラジオ→帯域、律速→ボトルネック・頭打ち、Traffic Rule→トラフィックルール）. Keep field-standard terms as-is（API・PoE・VLAN・SSID）. textlint cannot catch this — read for it manually
- **内容の整合性**: does the draft contradict itself, and does it close what it opened? A problem introduced as 「2階の寝室が遅い」 that becomes 「私の部屋だけ遅い」 in a quoted line, and is then resolved only as 「2階でも速くなった」, leaves the reader holding an unanswered thread. Check that referents, scope, and numbers stay the same across the piece, and that every problem raised gets an outcome. No lint reaches this — it is the reason this pass is a human read
- **自分が持ち込んだ不整合**: in fix mode, re-read the passages you changed against their neighbours. Rewriting one sentence for 文末の変化 can leave a paragraph mixing 過去 and 現在（「向上しました」と「減っています」）, which is a defect you introduced, not one you found
- **初出の専門用語の導入**: don't start using a term in the body before its alias/definition appears — a VLAN labeled Default in a table, then called Trusted in prose with no bridge, reads as 唐突 → introduce on first use as「A（＝B、その役割）」. In fix mode, insert the introduction only when the definition already appears elsewhere in the text; otherwise report it as a finding for the author — inventing a definition violates the say-only-what-the-source-says guard

## Output

Findings table (report mode) or applied-fix summary (fix mode):

```markdown
| Pass | 重要度 | 箇所 | Before → After |
```

- 重要度: CRITICAL（意味が壊れている・事実が変わる）/ IMPORTANT（誤字・誤用・文法ミス、および明確なAI臭）/ LOW（表記の好み）。Present CRITICAL and IMPORTANT in the table. LOW: one aggregate line — count plus rule/kind names only（「ほか LOW 2件（訳→わけ等の表記）」), no Before→After. This keeps Pass 1 evidence visible without itemizing
- In fix mode, LOW findings are applied to the text like any other; the aggregate line reports them, it does not withhold them. Pass 1's orthography guard decides whether something is a finding at all — this rule governs only accepted findings and does not resurrect rewrites the guard excluded
- In fix mode, end with counts grouped by pass（textlint / リズム・統計 / AI臭 / 自然さ）and anything intentionally left alone (voice devices, quoted text)
