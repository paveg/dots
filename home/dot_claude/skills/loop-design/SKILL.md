---
name: loop-design
description: >
  Use when the user wants to set up a recurring or autonomous agent loop and needs to design it before running it. Triggers: 「ループを設計」「自律ループを 作りたい」「loop を組みたい」, turning a vague "I want a loop that does X" into a concrete spec, or choosing a runner (/loop, /schedule, ralph-loop, pr-monitor) for repeated work. NOT for running an already-designed loop, and NOT for one-off tasks.

disable-model-invocation: false
---

# Loop Design

A guided interview that turns "I want a loop for X" into a concrete, runnable loop spec. It produces design artifacts and stops — it does not run the loop or register any schedule.

**REQUIRED BACKGROUND:** `~/.claude/rules/loop-engineering.md` defines the conventions (STATE.md spine, autonomy staging, comprehension debt). This skill is the _process_ that produces a spec conforming to them; it does not restate them.

## When to use

- The user wants a repeated/automated agent process and the shape is not yet pinned down.
- A loop is worth designing before running because it will act across runs without a human in every turn.

Do NOT use for a one-shot task, or to run a loop whose design already exists.

## The interview — one question at a time

Ask these in order, one per message. Do not assume answers; if the user gives a vague goal, the whole point is to extract the rest by asking. Skip a question only if the user already answered it.

| #   | Ask                                                                                             | Captures                              |
| --- | ----------------------------------------------------------------------------------------------- | ------------------------------------- |
| 1   | What does the loop converge toward, and how do you know it's done / when does it stop?          | goal + done/stop                      |
| 2   | What triggers it — `/loop <interval>`, `/schedule <cron>`, ralph-loop, pr-monitor, or an event? | runner                                |
| 3   | Who writes and who independently checks each iteration?                                         | maker/checker (generator ≠ evaluator) |
| 4   | What mechanical gates must pass every iteration (tests, CI, lint, checker verdict)?             | gates that earn autonomy              |
| 5   | What does this loop's STATE.md need to track (done / next / decisions / open questions)?        | spine schema                          |
| 6   | What must be true before it graduates report-only → assisted → unattended?                      | autonomy staging                      |
| 7   | When does a human read the diff the loop shipped, and what stops the loop?                      | comprehension-debt checkpoint         |

## Output

After the interview, write two files at the loop's working root (ask: repo root, or a worktree) and print one launch command:

1. `LOOP.md` — the spec (template below).
2. `STATE.md` — initialized skeleton, ready for run 1.
3. A copy-paste launch command, **pinned to report-only**. Print it; never run it.

### LOOP.md template

```markdown
# Loop: <name>

## Goal / Done

<what it converges toward; stop criteria>

## Runner

<runner> — <why this one>

## Maker / Checker

- Maker: <who writes>
- Checker: <independent verifier>

## Gates (each iteration)

- <tests / CI / lint / checker verdict>

## Autonomy

- Stage: report-only
- → assisted when: <gate that must fire on a real failure first>
- → unattended when: <mechanical gate proven on a real regression>

## STATE.md

- Location: <repo root | worktree>
- Tracks: done, next, decisions, open questions

## Comprehension-debt checkpoint

- <when the human reads the shipped diff; stop condition>
```

### STATE.md skeleton

```markdown
# STATE — <loop name>

Read at the start of every iteration; write at the end. One run's working spine — see loop-engineering.md.

## Done

- (nothing yet)

## Next

- (first action)

## Decisions

- (load-bearing decisions for this run)

## Open questions

- (none yet)
```

## Guardrails

- Start every new loop at **report-only**. Never emit an unattended launch command on first design.
- Stop at artifacts. Running the loop or registering a schedule is a separate, explicit step the user takes.
- Reference `loop-engineering.md` for "what good looks like"; do not paste its contents into LOOP.md.

## Common mistakes

- Producing a design without asking — the value is the interview. A vague goal is the signal to ask more, not to assume.
- Inventing a runner the user didn't choose, or skipping the maker/checker split.
- Emitting an unattended or auto-merge launch command. Report-only first, always.
