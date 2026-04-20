---
name: empirical-prompt-tuning
description: |
  Iteratively improve agent-facing text instructions (skills, slash commands, task prompts, CLAUDE.md sections, code-generation prompts)
  by having a bias-free executor run them and evaluating from both sides (executor self-report + caller-side metrics).
  Repeat until improvement plateaus.
  Use immediately after creating or significantly revising a skill/prompt, or when unexpected agent behavior is suspected to stem from ambiguous instructions.
argument-hint: Path or name of the prompt/skill to tune (e.g., dot_claude/skills/my-skill/SKILL.md)
---

# Empirical Prompt Tuning

Prompt quality is invisible to its author. The more "clear" a writer thinks something is, the more likely a fresh executor stumbles on it. **The core of this skill: have a bias-free executor actually run the prompt, evaluate from both sides, and iterate until improvement plateaus.**

## When to use

- Immediately after creating or significantly revising a skill / slash command / task prompt
- When an agent isn't behaving as expected and the root cause may be ambiguous instructions
- When hardening high-value instructions (frequently used skills, automation-critical prompts)

Do NOT use for:
- One-shot throwaway prompts (evaluation cost outweighs benefit)
- Cases where the goal is reflecting the author's subjective style preference, not improving success rate

## Scope: Global vs. Project prompts

This skill applies to **both** scopes equally. The evaluation workflow is identical; only the file location differs.

| Scope | Typical paths | Examples |
|---|---|---|
| **Global** (`~/.claude/`) | `~/.claude/skills/*/SKILL.md`, `~/.claude/rules/*.md`, `~/.claude/CLAUDE.md` | Reusable skills shared across all repos, global behavior rules |
| **Project** (repo-local) | `CLAUDE.md`, `docs/adr/*.md`, inline task prompts, CI prompt snippets | Project-specific instructions, ADRs with embedded prompts |

When tuning a global prompt, consider that it will run across many different project contexts — design scenarios that span 2–3 representative project types, not just the repo where you noticed the problem.

**Always edit the chezmoi source** at `~/.local/share/chezmoi/dot_claude/` — never edit `~/.claude/` directly. Changes to the live path are overwritten by the next `chezmoi apply`. After each iteration's fix, confirm with the user before running `chezmoi apply` to reflect the change.

## Workflow

### Step 0 — Description/Body Consistency Check (static, no dispatch needed)

Read the frontmatter `description` and the body independently.

- Does the description's stated trigger / use-case match what the body actually covers?
- Example mismatch: description says "navigation / form filling / data extraction" but body only contains `npx playwright test` CLI reference
- If there's a gap, fix description or body before proceeding to iter 1
- Skipping this causes subagents to "reinterpret" the body to fit the description, producing false-positive accuracy

### Step 1 — Prepare Baseline

Fix these two artifacts before dispatching any subagent:

**Evaluation scenarios** (2–3):
- 1 median-difficulty scenario representing typical real-world usage
- 1–2 edge scenarios

**Requirements checklist** (3–7 items per scenario):
- Each item = a concrete verifiable requirement the output must satisfy
- Tag at least 1 item `[critical]` per scenario
- **Do not modify the checklist after fixing it** — accuracy = items satisfied / total items

### Step 2 — Bias-Free Read

Dispatch a **new subagent** via the Agent tool. Never self-review (you cannot objectively read text you just wrote — this is structurally impossible).

When running multiple scenarios in parallel, place all Agent calls in a single message.

See "Environment Constraints" if dispatch is unavailable.

### Step 3 — Execute

Pass the subagent a prompt following the **Subagent Launch Contract** below. The subagent implements/generates the output and returns a self-report.

### Step 4 — Dual-Side Evaluation

Record the following from the returned result:

**Executor self-report** (extracted from the subagent's report):
- Unclear points / ambiguous wording
- Discretionary fill-ins (decisions not covered by the instructions)

**Caller-side measurements** (judgment rules are authoritative here — reference only this section):
- **Success/Failure**: SUCCESS (○) only if **all** `[critical]` items are ○. Any `[critical]` item that is × or partial = FAILURE (×). Binary only — no "partial success".
- **Accuracy**: % of checklist items satisfied. ○ = 1.0, × = 0.0, partial = 0.5. Sum divided by total items.
- **Step count**: `tool_uses` from Agent tool's usage metadata (include Read / Grep — no exclusions)
- **Duration**: `duration_ms` from Agent tool's usage metadata
- **Retry count**: how many times the executor reconsidered the same decision (from self-report; not measurable by caller)
- **On failure**: append one line to the "Unclear Points" section stating which `[critical]` item failed and why

Requirements checklist must contain **at least 1 `[critical]` item** (0 items makes success vacuously true). Do not add or remove `[critical]` tags after fixing the checklist.

### Step 5 — Apply Diff

Apply the minimal fix that addresses one theme of unclear points. Scope per iteration:
- **1 theme per iteration** (related micro-fixes count as 1 theme; unrelated fixes go to the next iter)
- Before applying: state which checklist item / judgment criterion this fix satisfies (axis names and judgment criteria are different — map to the criterion text, not the axis label)
- **Edit the chezmoi source** (`~/.local/share/chezmoi/dot_claude/`), never `~/.claude/` directly. After editing, confirm with the user before running `chezmoi apply`.

### Step 6 — Re-evaluate

Dispatch a **new** subagent (never reuse — it learned from the previous run). Repeat steps 2–5.

Increase parallelism when improvement is not plateauing.

### Step 7 — Convergence Check

Stop when **both** of the following hold for **2 consecutive iterations**:
- No new unclear points
- All quantitative thresholds met (see "Stopping Criteria")

For high-value prompts: require 3 consecutive iterations.

---

## Evaluation Axes

| Axis | Source | Meaning |
|---|---|---|
| Success/Failure | Caller measures | Minimum bar |
| Accuracy | Caller measures | Degree of partial success |
| Step count | `tool_uses` metadata | Proxy for wasted effort |
| Duration | `duration_ms` metadata | Proxy for cognitive load |
| Retry count | Executor self-report | Signal of ambiguity |
| Unclear points | Executor self-report | Qualitative improvement material |
| Discretionary fill-ins | Executor self-report | Surfacing implicit spec |

**Weighting**: qualitative (unclear points, fill-ins) is primary; quantitative (time, steps) is supplementary. Chasing only time reduction causes the prompt to become too sparse.

### Qualitative Interpretation of `tool_uses`

Use `tool_uses` as a **relative value across scenarios**, not an absolute target:

- If one scenario uses 3–5× more steps than others: the skill lacks self-contained recipe for that scenario and forces the executor into references descent
- Example: all scenarios at 1–3 `tool_uses` but one at 15+ → no recipe for that scenario; executor is traversing references/
- Fix: add "minimum complete example inline" or "when to read references" guidance at the top of SKILL.md

Even at 100% accuracy, a `tool_uses` outlier justifies starting iter 2.

### Fix Propagation Patterns

Fixes are non-linear. Three patterns to expect:

- **Conservative** (estimate > actual): fix targeted multiple axes, only moved one. "Multi-axis targeting often misses."
- **Upward** (estimate < actual): one structural piece of information (command + config + expected output combo) simultaneously satisfied multiple judgment criteria. "Information combos can hit multiple axes structurally."
- **Zero** (estimate > 0, actual = 0): the fix was inferred from the axis name but didn't map to any judgment criterion text. "Axis names and judgment criteria are different things."

To stabilize estimates: **before applying a fix, have the subagent state which judgment criterion text it satisfies**. Without criterion-level mapping, estimate accuracy stays low.

---

## Subagent Launch Contract

The prompt passed to each executor subagent must follow this structure:

```
You are a fresh executor reading <target prompt name> with no prior context.

## Target Prompt
<paste full text, or specify path for the subagent to Read>

## Scenario
<1-paragraph situation description>

## Requirements Checklist (what the output must satisfy)
1. [critical] <minimum bar item>
2. <standard item>
3. <standard item>
...
(Judgment rules are defined in the "Dual-Side Evaluation" section of the empirical-prompt-tuning skill. [critical] tag required on at least 1 item.)

## Task
1. Execute the scenario following the target prompt. Generate the deliverable.
2. At the end, return a report in the structure below.

## Report Structure
- Deliverable: <generated output or execution summary>
- Requirements met: for each item, ○ / × / partial (with reason)
- Unclear points: wording that caused confusion or required interpretation (bulleted list)
- Discretionary fill-ins: decisions not covered by instructions that you made yourself (bulleted list)
- Retries: how many times you reconsidered the same decision, and why
```

The caller extracts the self-report section and reads `tool_uses` / `duration_ms` from the Agent tool's usage metadata to fill the evaluation table.

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

## Presentation Format

Record and present after each iteration:

```
## Iteration N

### Changes (diff from previous)
- <1-line description of modification>

### Results (per scenario)
| Scenario | Pass/Fail | Accuracy | steps | duration | retries |
|---|---|---|---|---|---|
| A | ○ | 90% | 4 | 20s | 0 |
| B | × | 60% | 9 | 41s | 2 |

### Unclear Points (new this iteration)
- <Scenario B>: [critical] item N is × — <1-line reason>   # required on failure
- <Scenario B>: <other finding>
- <Scenario A>: (none)

### Discretionary Fill-ins (new this iteration)
- <Scenario B>: <decision made>

### Next Fix
- <1-line minimal modification>

(Convergence: N consecutive clears / Y more to stop)
```

---

## Red Flags

| Rationalization | Reality |
|---|---|
| "Reading it myself is the same thing" | You cannot objectively read text you just wrote. Always dispatch a new subagent. |
| "One scenario is enough" | Single scenarios overfit. Minimum 2, ideally 3. |
| "Zero unclear points once means we're done" | Could be chance. Require 2 consecutive iterations. |
| "Let me fix multiple unclear points at once" | You won't know what worked. 1 theme per iteration. |
| "Related micro-fixes should each be their own iteration" | Opposite trap. 1 theme = semantic unit. 2–3 related micro-fixes belong in 1 iter. Over-splitting explodes iteration count. |
| "Metrics look good, ignore qualitative feedback" | Time reduction alone is a sign of over-pruning. Qualitative is primary. |
| "Rewriting is faster" | Correct after 3+ iterations of no progress. Before that, it's avoidance. |
| "Reuse the same subagent" | It learned from the previous run. Dispatch fresh every iteration. |

---

## Common Mistakes

- **Scenario too easy / too hard**: neither produces useful signal. Target 1 median real-world case, 1 edge
- **Metrics-only evaluation**: chasing time reduction alone strips important guidance and makes the prompt brittle
- **Too many changes per iteration**: you lose track of which change caused which improvement. 1 fix = 1 iteration
- **Tuning scenarios to match fixes**: simplifying scenarios to make unclear points disappear is backwards

---

## Related

- `feature` — feature development with harness engineering. Same generator-evaluator separation principle applies
- `interrupt` — background agent dispatch. Reference for how to structure subagent launch prompts
