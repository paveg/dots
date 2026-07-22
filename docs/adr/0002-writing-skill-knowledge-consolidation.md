# 0002. Consolidate Japanese writing-skill knowledge into one canonical reference

## Status

Proposed — 2026-07-22. Revises the "Assets" decision in [ADR 0001](0001-japanese-writing-auto-trigger.md).

## Context

ADR 0001 proposed adding `cognitive-rhythm-writing` as a standalone skill. In review the user raised a topology concern: adding a fourth writing skill increases management overhead and wastes context, because the writing-skill family already **duplicates the same norms across four homes**.

Decomposing each member into _knowledge_ vs _process_ makes the real overlap visible:

| Layer                                                                                                                   | technical-writing                                          | article-writing                                                | proofreader                                                                | japanese-writing.md (always-on) |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------- |
| **Shared knowledge** (conclusion-first, register discipline, sourcing/faithfulness, sentence rhythm, AI-smell taxonomy) | ○                                                          | ○                                                              | ○ (passes)                                                                 | ○                               |
| Process (distinct)                                                                                                      | single-pass generation, notation tables, procedure shaping | 7-phase workflow, checkpoints, fact-check gate, style profiles | textlint/`lint.py` tooling, report/fix modes, voice preservation, 4 passes | —                               |
| Kind                                                                                                                    | generation                                                 | generation (heavy)                                             | **verification**                                                           | norms                           |

Two facts fall out:

1. **Only the knowledge is duplicated.** Conclusion-first, sourcing discipline, rhythm, and the AI-smell taxonomy are restated four times. That fourfold copy — not the count of always-loaded skill descriptions — is the substance of "management is getting complex." Adding `cognitive-rhythm` as a fifth home would worsen it.
2. **The processes are genuinely distinct, and one boundary is hard.** `technical-writing` (single-pass repo docs) and `article-writing` (gated, public, multi-phase) are different workflows, not one persona switch. Generation ↔ verification is a hard line: folding the proofreader into a generator would make the same invocation grade its own output, violating generator-evaluator separation (`harness-engineering.md`).

**Precedent for the fix:** `dot_claude/references/model-profiles/` already deploys to `~/.claude/references/` and is loaded just-in-time by skills. It is an established home for shared references that are neither always-on rules nor invocable skills.

## Decision

Adopt **Option 2 — dedup the knowledge, keep the process wrappers separate.** The principle: _consolidate what is duplicated (norms); keep separate what is genuinely different (process, and the generation/verification boundary); have the wrappers reference the shared norms rather than restate them._

### Canonical norms reference

Create `dot_claude/references/japanese-writing/` (deploys to `~/.claude/references/japanese-writing/`) as the single source of truth for readable-Japanese norms:

- conclusion-first structure, register discipline (one register per document), sourcing / faithfulness, sentence rhythm (length variety / burstiness),
- **cognitive-rhythm structural principles** — 状況を更新する文 vs 文書を更新する文, hold unresolved tension, dense→sparse alternation, no self-reference to devices,
- the AI-smell taxonomy (mechanical lists, hype, over-emphasis, colon syntax, …).

It is loaded **just-in-time**, never always-on. `cognitive-rhythm` folds into this reference and is **not** created as a standalone skill — this supersedes ADR 0001's Assets decision.

### Thin wrappers, unchanged boundaries

The three existing skills stay separate and become thin, each pointing at the norms reference instead of restating it:

- `technical-writing` keeps its domain tactics (notation tables, procedure shaping, reader calibration) and references the norms.
- `article-writing` keeps its phases, gates, and style profiles, and references the norms.
- `japanese-ai-writing-proofreader` keeps its tooling (`textlint` / `lint.py`), modes, and voice preservation, and references the norms taxonomy for its judgment passes. It **stays a separate skill / invocation** — the hard generator-evaluator line is unchanged.

`japanese-writing.md` (the always-on rule) shrinks to a **minimal floor plus a pointer** to the reference. This removes the fourth copy and reduces the always-on footprint that ADR 0001 identified as the dilution source.

### Wiring back to ADR 0001

ADR 0001's Stage 0 injection points at the norms reference (plus the proofreader reminder), not at a standalone `cognitive-rhythm` skill. Generation, verification, and injection then all read **one** source.

Net: skill count stays at three (not four), norms live once, the hard boundary is preserved.

### Naming — deferred entirely to ADR 0003

The user also asked to unify skill naming. That is a global, breaking concern (invocation names, cross-references, memory, `CLAUDE.md`) and is handled in its own [ADR 0003](0003-skill-naming-convention.md). **This ADR renames nothing** — it keeps the current skill names (`technical-writing`, `article-writing`, `japanese-ai-writing-proofreader`) so the consolidation and any rename land as separate, independently-reviewable changes.

## Consequences

### Positive

- One source of truth for the norms; no fourfold drift.
- Slimmer always-on floor → less of the dilution ADR 0001 targets.
- ADR 0001's asset simplified: no new skill, one fewer thing to trigger.
- Hard generation/verification boundary intact.

### Negative / costs

- One-time migration touching three skills, one rule, and one new reference; every cross-reference (the two generators' "invoke proofreader" pointers, ADR 0001, memory, `CLAUDE.md`) must be repointed in the same change.
- **Over-stripping risk:** a wrapper reduced to a bare pointer loses its useful domain examples. Move only the shared _principle_; keep each skill's domain-specific _application_ and examples.
- The reference must resolve at `~/.claude/references/japanese-writing/` at runtime; verify chezmoi deploys it (`references/` is not in `.chezmoiignore`).

### Done criteria (verifiable)

- `dot_claude/references/japanese-writing/` exists, deploys, and contains the merged norms including the cognitive-rhythm principles.
- The three wrappers no longer restate the shared norms; each links the reference. A grep for a duplicated norm phrase resolves to a single home.
- `japanese-writing.md` is the minimal floor plus pointer.
- ADR 0001's Assets section references this ADR (no standalone cognitive-rhythm skill).
- No skill is renamed by this ADR; naming is ADR 0003's concern.
- `just test` passes.

### Follow-ups / out of scope

- Skill-naming convention and any rename — [ADR 0003](0003-skill-naming-convention.md).
- Review-response coverage (carried over from ADR 0001).
