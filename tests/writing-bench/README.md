# Writing Bench

Fixed benchmark for the Japanese writing stack (ADR 0006). Ten prompts in `prompts/`, mechanical scoring via `score.sh`, judgment via `rubric.md`. Run the full bench when `norms.md` or the writing skills change; the mechanical tier alone is near-free and can run anytime.

## When to run

- **Full run (generation + mechanical + judge)**: after any change to `home/dot_claude/references/japanese-writing/norms.md`, the `writing` / `writing-proofread` skills, or the always-on `japanese-writing.md` rule. This is a regression test for the change — compare against the previous run's scores.
- **Mechanical only**: anytime, on any run's outputs. `score.sh` costs nothing.
- Changing a prompt breaks comparability with every earlier run — treat task-set edits as their own versioned event (commit + note in the run log), never as part of a rules change.

## Procedure

1. **Generate.** For each `prompts/NN-*.md`, start a fresh Claude Code session on the everyday model and paste the prompt body (everything below the `<!-- bench: … -->` comment line). Save the produced artifact verbatim as `outputs/<run-id>/NN-<same-stem>.md`. `<run-id>` is `YYYY-MM-DD-<short-label>`. Don't coach the session; the point is to measure what the stack does unprompted.
2. **Score mechanically.** `./score.sh outputs/<run-id>` — writes one JSON per artifact into `outputs/<run-id>/scores/` and prints a one-line summary per file (volume/shape violations, rhythm-lint counts, prh hits).
3. **Judge.** In a separate opus session, follow `rubric.md` for each artifact; save each JSON verdict as `outputs/<run-id>/scores/NN-judge.json`.
4. **Compare.** Diff the score files against the previous run-id. A rules change that moves no metric and no judge axis did not earn its context cost.

`outputs/` is a local working area — keep it out of commits unless a run is worth preserving as calibration data.

## Prompt set (v1, 2026-08-19)

| #     | Artifact                 | Planted pressure                                                                  |
| ----- | ------------------------ | --------------------------------------------------------------------------------- |
| 01–03 | PR body ×3               | 40-line budget; 02 before/after diagram trigger, 03 sequence trigger              |
| 04–05 | Design doc ×2            | 04 state-transition trigger; 05 scope-mixing temptation (1 doc 1 purpose)         |
| 06–07 | README section / runbook | 06 general-engineer audience; 07 branching-procedure trigger, です・ます register |
| 08–09 | Article ×2               | 08 non-engineer audience vocabulary; 09 numbers-heavy sourcing                    |
| 10    | English-source explainer | Translationese trap (canonical / mitigation / deprecated / remediation)           |
