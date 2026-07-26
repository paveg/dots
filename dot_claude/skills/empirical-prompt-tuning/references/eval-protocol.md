# Evaluation Protocol

Read this when you reach Step 3 (dispatch) or Step 4 (evaluation). The main SKILL.md carries the loop; this file carries the measurement machinery, the launch template, and the reporting format.

## Evaluation Axes

| Axis                   | Source                 | Meaning                          |
| ---------------------- | ---------------------- | -------------------------------- |
| Success/Failure        | Caller measures        | Minimum bar                      |
| Accuracy               | Caller measures        | Degree of partial success        |
| Step count             | `tool_uses` metadata   | Proxy for wasted effort          |
| Duration               | `duration_ms` metadata | Proxy for cognitive load         |
| Retry count            | Executor self-report   | Signal of ambiguity              |
| Unclear points         | Executor self-report   | Qualitative improvement material |
| Discretionary fill-ins | Executor self-report   | Surfacing implicit spec          |

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

## Failure modes seen in practice

Kept as a record of what actually went wrong, not as a set of bans — the loop's non-negotiables live in SKILL.md.

| Rationalization                                          | Reality                                                                                                                    |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| "Reading it myself is the same thing"                    | You cannot objectively read text you just wrote. Always dispatch a new subagent.                                           |
| "One scenario is enough"                                 | Single scenarios overfit. Minimum 2, ideally 3.                                                                            |
| "Zero unclear points once means we're done"              | Could be chance. Require 2 consecutive iterations.                                                                         |
| "Let me fix multiple unclear points at once"             | You won't know what worked. 1 theme per iteration.                                                                         |
| "Related micro-fixes should each be their own iteration" | Opposite trap. 1 theme = semantic unit. 2–3 related micro-fixes belong in 1 iter. Over-splitting explodes iteration count. |
| "Metrics look good, ignore qualitative feedback"         | Time reduction alone is a sign of over-pruning. Qualitative is primary.                                                    |
| "Rewriting is faster"                                    | Correct after 3+ iterations of no progress. Before that, it's avoidance.                                                   |
| "Reuse the same subagent"                                | It learned from the previous run. Dispatch fresh every iteration.                                                          |

Design-level mistakes that produce useless signal:

- **Scenario too easy / too hard**: neither produces useful signal. Target 1 median real-world case, 1 edge
- **Metrics-only evaluation**: chasing time reduction alone strips important guidance and makes the prompt brittle
- **Too many changes per iteration**: you lose track of which change caused which improvement. 1 fix = 1 iteration
- **Tuning scenarios to match fixes**: simplifying scenarios to make unclear points disappear is backwards
