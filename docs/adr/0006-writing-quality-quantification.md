# 0006. Quantify Japanese writing quality: standing mechanical lint + change-driven opus judge

## Status

Accepted — 2026-08-19.

## Context

The Japanese writing stack (always-on floor rule, JIT `norms.md`, injection hooks, generation skills, proofreader — see ADR 0001/0002) has grown by iteration, but there is no way to measure whether a change to the norms or skills makes output more natural. Observed defects keep recurring: translationese vocabulary, documents exceeding the reader's comprehension budget, verbose prose where a diagram belongs. Without measurement, every rule tweak is a guess and the volume/structure targets now being added (design doc 2026-08-19) cannot be calibrated.

Constraints: the user's overriding requirement is context and token cost efficiency. A full LLM-judged benchmark run costs on the order of hundreds of thousands of tokens; naturalness, however, cannot be scored by deterministic metrics alone.

## Decision

Two-tier evaluation, mechanical-first, with the expensive tier gated on change events.

**Tier 1 — mechanical metrics (standing, near-free).** Reuse the proofreader's existing `lint.py`/`textcore.py` (sentence-length variance and paragraph-shape statistics are already implemented) and add thin aggregations: volume/structure budget-overrun counts and `prh.yml` hit counts. May run periodically or ad hoc at negligible cost.

**Tier 2 — fixed benchmark + LLM-as-judge (change-driven only).** A fixed set of 10 tasks in `tests/writing-bench/` (PR body ×3, design doc ×2, README/手順書 ×2, article ×2, translation-prone task ×1) is generated with the everyday main-session model and scored by an **opus judge in a separate session** (generator-evaluator separation). Rubric: 4 axes — naturalness, structure, volume, diagram judgment — each mapped to a `norms.md` section, scored 1–5. Full runs happen only when norms or writing skills change, as a regression test.

Runner stays primitive: a README with the procedure, the prompt set, and the scoring script. No dedicated skill until the loop has been operated in practice.

Rejected alternatives: periodic judge runs (cost without information when nothing changed); scoring real production artifacts continuously (operational burden, uncontrolled inputs); sonnet as judge (naturalness judgment quality is the benchmark's whole point; run frequency is low enough that per-run cost is secondary); mechanical metrics only (cannot measure naturalness, the primary target).

## Consequences

- Rule changes to the writing stack become measurable; the initial volume/structure targets are explicitly provisional and get recalibrated from benchmark data instead of debate.
- The fixed task set makes runs comparable across time; changing the task set breaks comparability and must be versioned as its own event.
- Judge-score validity is unproven until the first run is compared against the user's own judgment; if they diverge, the rubric — not the user — is what gets revised.
- Full runs are expensive by design and must stay change-gated; wiring them into anything periodic re-imports the cost this decision exists to avoid.
- Adds `tests/writing-bench/` to the repo test surface; the scoring additions land in the proofreader's script home to avoid a second lint implementation.
