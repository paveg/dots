# Japanese Writing Unification — Design

Date: 2026-08-19 Status: Approved (grill-me session)

## Context

Grilled how to make Claude's Japanese prose natural across artifact genres: translationese vocabulary (正本/正典 for "canonical") still leaks, documents blow past the reader's comprehension budget, verbose prose appears where a diagram belongs, and there is no way to measure whether rule changes improve anything. The session settled a unified norms layer, effort-target budgets, diagram triggers, a quantification harness, and a consolidation of the generation skills.

## Decisions

1. **Scope: file artifacts only** (GFM/Markdown — PR bodies, docs, articles). Chat responses are out of scope. The existing injection paths suffice: `japanese-writing-inject.sh` for `.md` writes, `gh-pr-inject.sh` for PR bodies. No new hooks.
2. **Unified core = `norms.md` extension.** No new layer; genre differences are register-level (ですます/断定 etc.) and stay as thin deltas inside genre skill material. Rejected: a separate unified-rules file (dual source of truth).
3. **Form follows information structure, not genre**: parallel enumerable facts (≥3 items, no logical connective between them) → bullet list; causal/argumentative flow (「だから」「しかし」 chains) → prose; comparison of multiple subjects on the same attribute axis → table. A logical connective appearing inside a bullet is the signal to fall back to prose. Lands in norms Structure section.
4. **Translationese defense in three layers**: (i) generation-time persona vocabulary test in norms; (ii) capture loop — every discovered translationese word is added to the proofreader's `prh.yml`, converting non-deterministic vocabulary into deterministic detection (one-line rule, no dedicated skill); (iii) proofreader Pass 3 gains an explicit 翻訳借用語 category.
5. **Audience section in norms**: fix the reader in one line before writing. Default reader = **general readers, not limited to engineers**; when the artifact is explicitly a technical document, the default is 一般的な日本のソフトウェアエンジニア. Vocabulary test: would that reader use the word aloud / understand it on first hearing. Genre skills may override the default. The user is never prompted for a persona per document.
6. **Volume effort targets** (not lint; initial values, recalibrated after the benchmark runs): sentence ≤ 60 字目安; paragraph ≤ 150 字 / 2–4 sentences; section ≤ 400 字 (exceeding → split with subheadings or convert to a diagram); PR body ≤ 40 lines (aligned with the proofreader's existing document-size threshold). Lands in a new norms Volume section.
7. **Structure effort targets** (same status as 6): heading depth ≤ h3 (needing h4 signals document split); 3–7 sections per document; list nesting ≤ 2 levels (a needed 3rd level → table or diagram); conclusion-first at section level, not only document level; 1 document = 1 purpose (split when the purpose forks — document analog of the pr-size rule).
8. **Diagram triggers, made explicit**: ≥3 participants exchanging calls → sequenceDiagram; ≥4 states in a transition → stateDiagram-v2; structural before/after comparison → side-by-side graphs; procedure of ≥5 steps containing branches → flowchart. Added to the always-loaded mermaid rule; in the same change the near-verbatim duplication between `mermaid-diagrams.md` and `markdown-formatting.md` is consolidated (keep `markdown-formatting.md`), so always-on context decreases net.
9. **Quantification = mechanical metrics + fixed benchmark with LLM judge** (see ADR 0006). Mechanical side reuses the proofreader's `lint.py`/`textcore.py` (sentence-length variance, paragraph shape already implemented) plus thin additions: budget-overrun counts and prh hit counts. Benchmark: 10 fixed tasks in `tests/writing-bench/` — PR body ×3, design doc ×2, README/手順書 ×2, article ×2, translation-prone task ×1.
10. **Judge = opus in a session separate from generation**; rubric with 4 axes (naturalness / structure / volume / diagram judgment), each mapped to a norms section, scored 1–5. Generation runs on the everyday main-session model.
11. **Execution timing**: full benchmark (with judge) only on norms/skill changes, as a regression test. Periodic runs are mechanical-metrics only (near-free). Rejected: periodic judge runs (cost without information when nothing changed).
12. **Runner stays primitive**: README with the run procedure + prompt set + scoring script. Skill-ification deferred until the loop has actually been operated.
13. **Generation skills consolidate** (see ADR 0007): article-writing + technical-writing → one `writing` skill. The proofreader stays a separate skill (generator-evaluator line) and is renamed `writing-proofread` per ADR 0003's family-stem rule, triggered now because this change substantively touches it.
14. **Router shape**: the consolidated skill is a thin router SKILL.md with per-mode detail in `references/` loaded just-in-time. Mode is auto-detected from the artifact destination — repository file → technical-document mode; public platform → article mode with the fact-check gate — asking the user only when ambiguous.
15. **Workflow-specific skills stay out**: `pr-description`, `x-post-craft`, `daily-kickoff` and similar are distinct workflows, not genre routing; they keep referencing norms and are not folded into the router.
16. **Global constraint honored throughout**: minimize always-loaded context; put everything possible behind JIT loading (norms reference, mode references) or deterministic tools (prh, lint.py).

## Open questions

- Whether the numeric targets in 6–7 actually track readability is unknown until the benchmark measures them — they are declared initial values, expected to be revised.
- Whether opus-judge scores correlate with the user's own readability judgment: needs a prototype (the first full benchmark run). Ungrillable by discussion.

## Out of scope

- Chat/terminal responses (Decision 1).
- Lint-enforcing the volume/structure targets (effort targets only, Decision 6).
- Folding the proofreader into the generator (Decision 13).
- Consolidating workflow-specific skills (Decision 15).
- Implementing any of the above — this document records the design only.

## Related decisions

- [ADR 0006](../../adr/0006-writing-quality-quantification.md) — quantification strategy
- [ADR 0007](../../adr/0007-writing-skill-consolidation.md) — generation-skill consolidation, partially revising ADR 0002
