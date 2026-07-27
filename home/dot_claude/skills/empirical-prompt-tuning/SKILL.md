---
name: empirical-prompt-tuning
description: >-
  Improve agent-facing text instructions (skills, slash commands, task prompts, CLAUDE.md sections) by having a bias-free executor actually run them, then evaluating from both sides until improvement plateaus. Use right after creating or significantly revising a prompt, or when odd agent behavior looks like ambiguous instructions rather than a bug.
argument-hint: Path or name of the prompt/skill to tune (e.g., home/dot_claude/skills/my-skill/SKILL.md)
---

# Empirical Prompt Tuning

Prompt quality is invisible to its author. The more "clear" a writer thinks something is, the more likely a fresh executor stumbles on it. **The core of this skill: have a bias-free executor actually run the prompt, evaluate from both sides, and iterate until improvement plateaus.**

## Non-negotiables

- Never self-review. You cannot objectively read text you just wrote, and a self-scored loop drifts toward leniency
- Dispatch a fresh subagent every iteration — a reused one already learned the answers
- One theme per iteration, minimum 2 scenarios, 2 consecutive clean iterations before stopping
- Qualitative signal (unclear points, discretionary fill-ins) outranks time and step counts

`references/eval-protocol.md` records the rationalizations that led to violating each of these.

## Before you start

- Load `~/.claude/references/model-profiles/<session-model-id>.md` and apply its Remove / Rewrite / Keep guidance when judging and editing the target — it is where model-specific writing changes live. No profile match → fall back to the nearest same-family one and note the gap.
- Dispatch executors and judges at the session model by default. Do not hardcode a model name in the target prompt; name a model only for a mechanical substep. A prompt pinned to today's model re-breaks on the next upgrade.
- When the target is a skill, read it through the `skill-creator` (Anthropic official) methodology first — it names the structural defects to look for. If `skill-creator` is not available in this environment, read for the same defects manually: unclear trigger in `description`, missing prerequisites, steps that assume unstated context.

## Two modes

- **Light** (eval-free triage): for taking inventory across many prompts, or a first pass. Dispatch one reading-check subagent with the target body only (no execution) and ask where it would hesitate, what it would guess, what prerequisite is missing. Fix what that surfaces. Cheap; use it to decide which prompts earn the full loop.
- **Full** (eval loop): the rest of this skill. Reserve for high-value or misbehaving prompts — one loop costs `scenarios × (execute + judge) × iterations` subagent launches.

## When to use

- Immediately after creating or significantly revising a skill / slash command / task prompt
- When an agent isn't behaving as expected and the root cause may be ambiguous instructions
- When hardening high-value instructions (frequently used skills, automation-critical prompts)

Do NOT use for:

- One-shot throwaway prompts (evaluation cost outweighs benefit)
- Cases where the goal is reflecting the author's subjective style preference, not improving success rate

## Scope: Global vs. Project prompts

This skill applies to **both** scopes equally. The evaluation workflow is identical; only the file location differs.

| Scope                     | Typical paths                                                                | Examples                                                       |
| ------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------- |
| **Global** (`~/.claude/`) | `~/.claude/skills/*/SKILL.md`, `~/.claude/rules/*.md`, `~/.claude/CLAUDE.md` | Reusable skills shared across all repos, global behavior rules |
| **Project** (repo-local)  | `CLAUDE.md`, `docs/adr/*.md`, inline task prompts, CI prompt snippets        | Project-specific instructions, ADRs with embedded prompts      |

When tuning a global prompt, consider that it will run across many different project contexts — design scenarios that span 2–3 representative project types, not just the repo where you noticed the problem.

**Always edit the chezmoi source** at `~/.local/share/chezmoi/home/dot_claude/` — never edit `~/.claude/` directly. Changes to the live path are overwritten by the next `chezmoi apply`. After each iteration's fix, confirm with the user before running `chezmoi apply` to reflect the change.

## Workflow

### Step 0 — Description/Body Consistency Check (static, no dispatch needed)

Read the frontmatter `description` and the body independently.

- Does the description's stated trigger / use-case match what the body actually covers?
- Example mismatch: description says "navigation / form filling / data extraction" but body only contains `npx playwright test` CLI reference
- If there's a gap, fix description or body before proceeding to iter 1
- Skipping this causes subagents to "reinterpret" the body to fit the description, producing false-positive accuracy

### Step 1 — Prepare Baseline

Fix these two artifacts before dispatching any subagent:

**Evaluation scenarios** (2–3 for the loop, plus 1 sealed hold-out):

- 1 median-difficulty scenario representing typical real-world usage
- 1–2 edge scenarios
- 1 additional hold-out, sealed: never used during the loop, run once at convergence (see Stopping Criteria → Overfitting check) to detect overfitting. This is on top of the 2–3 loop scenarios, so the loop always keeps its minimum of 2.

**Requirements checklist** (3–7 items per scenario):

- Each item = a concrete verifiable requirement the output must satisfy
- Tag at least 1 item `[critical]` per scenario
- Do not loosen the checklist after fixing it — accuracy = items satisfied / total items. The only permitted change is tightening (a stricter bar or a new item); if you tighten, re-run every scenario from scratch.

### Step 2 — Bias-Free Read

Dispatch a **new subagent** via the Agent tool. When running multiple scenarios in parallel, place all Agent calls in a single message. See "Environment Constraints" if dispatch is unavailable.

### Step 3 — Execute

Pass the subagent a prompt following the **Subagent Launch Contract** in `references/eval-protocol.md`. The subagent implements/generates the output and returns a self-report.

### Step 4 — Dual-Side Evaluation

Read `references/eval-protocol.md` for the axis definitions and the `tool_uses` interpretation. Record from the returned result:

**Executor self-report**: unclear points / ambiguous wording, and discretionary fill-ins (decisions not covered by the instructions).

**Who judges** (the improver stays out of subjective scoring):

- Mechanical criteria — tie pass/fail to a verification command (exit code / output string / diff). No model judgment.
- Non-mechanical criteria — dispatch a separate judge subagent that sees only the deliverable and the criteria, never the target's diff, the iteration history, or the improvement intent. The executor's own ○ / × / partial is provisional signal; the judge's verdict is authoritative.
- Persist each run's full transcript to a file; return only the fail list and confusion summary to the improver's context, not the whole log. Keep the eval set (scenarios, verification commands, per-iteration logs) in the repo alongside the target so a human can audit it later.

**Caller-side measurements** (judgment rules are authoritative here — reference only this section):

- **Success/Failure**: SUCCESS (○) only if **all** `[critical]` items are ○. Any `[critical]` item that is × or partial = FAILURE (×). Binary only — no "partial success".
- **Accuracy**: % of checklist items satisfied. ○ = 1.0, × = 0.0, partial = 0.5. Sum divided by total items.
- **Step count**: `tool_uses` from Agent tool's usage metadata (include Read / Grep — no exclusions)
- **Duration**: `duration_ms` from Agent tool's usage metadata
- **Retry count**: how many times the executor reconsidered the same decision (from self-report; not measurable by caller)
- **On failure**: append one line to the "Unclear Points" section stating which `[critical]` item failed and why

The checklist must contain **at least 1 `[critical]` item** (0 items makes success vacuously true). Do not add or remove `[critical]` tags after fixing the checklist.

### Step 5 — Apply Diff

Apply the minimal fix that addresses one theme of unclear points.

- **1 theme per iteration** (related micro-fixes count as 1 theme; unrelated fixes go to the next iter)
- Before applying: state which checklist item / judgment criterion this fix satisfies. Axis names and judgment criteria are different things — map to the criterion text, not the axis label
- **Edit the chezmoi source** (`~/.local/share/chezmoi/home/dot_claude/`), never `~/.claude/` directly. After editing, confirm with the user before running `chezmoi apply`.

### Step 6 — Re-evaluate

Dispatch a **new** subagent and repeat steps 2–5. Increase parallelism when improvement is not plateauing.

### Step 7 — Convergence Check

Stop when **both** hold for **2 consecutive iterations**: no new unclear points, and all quantitative thresholds met (see "Stopping Criteria"). For high-value prompts: require 3 consecutive iterations.

Report each iteration in the format given in `references/eval-protocol.md`.

---

## Environment Constraints

If dispatching a new subagent is not possible (already running as a subagent, Task tool disabled, etc.):

- **Do not apply this skill.**
- Option A: Ask the user to open a separate Claude Code session
- Option B: Report `empirical evaluation skipped: dispatch unavailable` and stop
- **Never substitute self-review** — the bias makes the results meaningless

**Structure Audit Mode**: if the goal is checking textual consistency / clarity only (not running the prompt), mark the subagent prompt explicitly as "structure audit mode: text consistency check only, not execution." This prevents the environment-constraint skip rule from triggering. Structure audits are a supplement to empirical evaluation — they do not count toward convergence.

---

## Stopping Criteria

**Convergence (stop)**: all of the following hold for 2 consecutive iterations:

- New unclear points: 0
- Accuracy improvement vs. previous iter: ≤ +3 percentage points
- Step count change vs. previous iter: ≤ ±10%
- Duration change vs. previous iter: ≤ ±15%
- **Overfitting check**: at convergence, run 1 hold-out scenario not used in previous iters. If accuracy drops ≥ 15 points from the recent average, overfitting has occurred — return to scenario design and add more edge cases.

**Divergence (redesign)**: 3+ iterations with no reduction in new unclear points → the prompt's structural design is wrong. Stop patching; rewrite the structure.

**Resource cutoff**: when improvement cost no longer justifies improvement value (shipping at 80 is a valid call).

---

## Related

- `references/eval-protocol.md` — axes, launch contract, reporting format, recorded failure modes
- `context-diet` — cut a prompt's token cost; run it before tuning so the loop measures the shape you intend to keep
- `feature` — feature development with harness engineering. Same generator-evaluator separation principle applies
- `claude-md-layout` — designs directory-level CLAUDE.md; use its with/without check to verify a moved convention still changes behavior
- `references/model-profiles/` — the swappable per-model profile this skill loads in "Before you start"
