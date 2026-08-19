---
name: writing
description: >-
  Write or revise Japanese documents of any genre through one entry point — blog/tech articles (funailog / Zenn / note) and repo documents (README sections, design docs, runbooks/手順書, operations guides, API docs), including turning memos/logs/repos into either. Mode is picked from the artifact's destination, not by the caller. Triggers: 「記事を書く」「ブログ記事」「記事化して」「技術ドキュメントを書いて」「READMEに追記して」「手順書を作って」「設計ドキュメントをまとめて」. Prose-level proofreading of finished text goes to writing-proofread.

argument-hint: <topic / target file / source material>
---

# Writing (Japanese documents)

One skill, two modes. Route by the artifact's destination, then read ONLY the chosen mode's reference and follow it as the process — do not load the other mode.

## Mode selection

| Destination                                                         | Mode      | Process reference         |
| ------------------------------------------------------------------- | --------- | ------------------------- |
| Repository file（README・docs/・手順書・設計文書・PR/issue 本文級） | technical | `references/technical.md` |
| Public platform（funailog / Zenn / note / 外部ブログ）              | article   | `references/article.md`   |

When the destination is ambiguous（社内メモをいずれ公開するかも、等）, ask which mode before writing. The article mode's fact-check gate is the difference between the two, and silently skipping it is the one routing failure this table must not allow.

## Common ground (both modes)

- Read `~/.claude/references/japanese-writing/norms.md` once before drafting — audience default, structure, volume/shape targets, rhythm, and the AI-smell taxonomy all live there and are not restated in the mode references.
- Repo conventions (`.claude/rules/`, `CLAUDE.md`, frontmatter schemas, build commands) override this skill on everything they specify; this skill owns the process.
- Proofreading belongs to `writing-proofread`: the article mode invokes it as a phase; the technical mode leaves it to an explicit user request（校正して）.
