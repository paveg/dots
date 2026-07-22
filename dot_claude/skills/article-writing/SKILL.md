---
name: article-writing
description: >-
  Step-by-step article writing workflow with style selection (personal voice vs serious), a hallucination-prevention fact-check gate, and AI-smell proofreading. Use when writing or co-writing blog/tech articles — triggers: 「記事を書く」「ブログ記事」「記事化して」, turning memos/logs/repos into an article, or drafting for funailog/Zenn/note. For proofreading-only requests, use the japanese-ai-writing-proofreader skill directly.

argument-hint: <topic or source material>
---

# Article Writing

Write articles in distinct phases with user checkpoints. Never skip ahead: each phase's output is the next phase's input, and the fact-check gate exists precisely because drafting and verifying in one pass lets hallucinations through.

## Phase 0: Repo conventions

If the working repo has article-related conventions (`.claude/rules/`, `CLAUDE.md`, frontmatter schemas, category/series definitions, build commands), read and follow them. They override this skill on **everything they specify — including prose style**（調・一人称・締めの形式）. The style profiles in `references/` fill in only what the repo leaves unspecified (rhythm, structure, character devices). This skill always owns the process (the phases and gates).

## Phase 1: 企画 — CHECKPOINT

Confirm with the user before writing anything:

- **題材とソース**: what the article is about, and what raw material exists (repo, logs, memos, URLs, receipts, chat history)
- **想定読者と媒体**: who reads it, where it lands (funailog / Zenn / etc.)
- **文体**: ask the user to choose
  - `personal` — キャラあり。`references/style-personal.md`
  - `serious` — キャラ控えめ。`references/style-serious.md`
- **分量の目安** and any deadline

## Phase 2: 素材収集

Gather facts BEFORE outlining. Build a 素材ノート (working notes file or message) where every fact is paired with its source:

```markdown
- 引っ越しタスク総数: 103 — Todoist export, section count 9
- ICL費用: 693,000円 — 領収書 (内金330,000 + 当日363,000)
```

- For repos: dispatch Explore subagents; have them return claims WITH file paths and line numbers, not summaries
- For URLs: fetch and note which page supports which fact
- Numbers, model names, versions: record exact values with units

Facts not in the 素材ノート do not go in the draft. If a section needs a fact you don't have, collect it now or mark the gap for the user.

## Phase 3: 構成案 — CHECKPOINT

Present an outline for approval:

- Section list with the one key message per section
- Which 素材ノート entries feed each section
- Proposed title (+ description/frontmatter if the repo schema needs it)

Iterate here until approved. Restructuring an outline is cheap; restructuring a draft is not.

## Phase 4: 起稿

1. Read the chosen style profile in `references/` — every time, not from memory
2. If past articles are available (repo-local or the profile's excerpts), read 2-3 as few-shot calibration before writing
3. Draft the full article following the outline
4. Constraints while drafting:
   - Every factual statement must trace to the 素材ノート
   - Concrete numbers over adjectives; bold ≈ one key claim per section
   - Apply the shared norms (`~/.claude/references/japanese-writing/norms.md`) for rhythm and structure, then layer the style profile's rhythm rules (sentence-end variety, long-short contrast) on top — the profile's markers matter less than the norms underneath them

## Phase 5: ファクトチェック＋公開可否 — GATE

Follow `references/fact-check.md`: extract every verifiable claim, verify each against a primary source, resolve all failures (fix / downgrade / delete / flag). For articles describing personal infrastructure or accounts (自宅ネットワーク・自宅サーバ・スマートホーム), also run the disclosure sweep (§5) in that reference: scan for real identifiers (SSID・認証情報・公開IP・ホスト名・機器ブランド) and genericize or redact. Present the claims table. **Do not proceed with unresolved items.**

## Phase 6: 校正

Invoke the `japanese-ai-writing-proofreader` skill on the draft in fix mode (the draft is Claude-written). It runs textlint, removes AI-smell, and checks deep naturalness against the shared norms (`~/.claude/references/japanese-writing/norms.md`). Re-read the result against the style profile: proofreading must not have flattened the chosen voice.

## Phase 7: 完成レポート — CHECKPOINT

Deliver to the user:

- The final draft
- Fact-check summary (verified / fixed / downgraded / flagged counts) and the list of items needing manual confirmation (実測値、金額の公開可否など)
- Proofreading summary (what categories of fixes were applied)
- Repo-specific next steps if applicable (frontmatter `isPublished`, build check, PR) — only execute these when the user asks
