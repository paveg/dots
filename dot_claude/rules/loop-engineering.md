---
paths:
  - "**/STATE.md"
  - "**/LOOP.md"
  - "**/run-log*"
  - "**/run-logs/**"
---

# Loop Engineering

Conventions for autonomous or long-running agent loops (`/loop`, `/schedule`,
ralph-loop, pr-monitor) — where the agent iterates toward a goal across runs
without a human in every turn.
Most of the machinery lives in other rules; this file covers only what loops add.

Reuse, do not restate:

- Maker/checker split is the generator-evaluator separation in `harness-engineering.md`. The writer never grades its own homework.
- "Stronger verification earns more autonomy", and where to enforce a constraint, is the escalation ladder in `harness-meta.md`.

## STATE.md — the loop's spine

A loop's conversation is volatile; the repo is not.
Persist what a run needs to resume in a `STATE.md` at the loop's working root
(repo or worktree), and read it at the start of every iteration.

- Holds **what's done** and **what's next**, plus open questions and the load-bearing decisions of THIS run.
- Keep it distinct from the other memory layers, and do not mix them:
  - persistent memory (`~/.claude/.../memory/`) — cross-session facts Claude recalls.
  - `.ai/` — the user's learning notes (see `repo-notes.md`).
  - STATE.md — one autonomous run's working state, disposable once the loop ends.
- Decisions that outlive the loop graduate to an ADR (`harness-engineering.md`), not STATE.md.
- History and rationale never go in code comments — that is comment rot (`development-principles.md`); STATE.md and git carry history.

## Autonomy staging

Graduate a loop's trust over runs; never start unattended.
These names are descriptive, separate from the `harness-meta.md` L1–L4 ladder
(which is about where a constraint lives, not how much a loop is trusted).

- **report-only** — the loop discovers and proposes; a human applies. Start every new loop here.
- **assisted** — patch-only or single-file fixes behind a gate; risky or ambiguous calls still escalate.
- **unattended** — only after the mechanical gates (tests, CI, checker subagent) have caught a real regression on this loop.

Promote a stage only when the gate beneath it has actually fired on a real
failure. Promotion is earned by evidence, not by elapsed time.

## Comprehension debt

> The faster the loop ships code you did not write, the bigger the gap between
> what exists and what you actually get.

- Read the diff a loop ships before the next iteration builds on it. A green checker subagent is not a license to skip reading.
- If you cannot explain what the last run changed, stop the loop and catch up before the gap compounds.
