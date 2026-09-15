# empirical-prompt-tuning log — 2026-09-15

Targets: `~/.claude/rules/harness-engineering.md`, `~/.claude/rules/workflow.md` (theme: 検証は主張の成立を確かめる). Red/Green only: `development-principles.md` (3 sentences).
Fixtures: `/tmp/ept/fixtures/`. Checklists: `/tmp/ept/checklists.md` (frozen). Executors: session model (fable). Judges: sonnet.

## Iteration 0 (Red: current rules, no added text)

| Scenario                               | Pass/Fail | Accuracy | notes                                                                                                                                       |
| -------------------------------------- | --------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| A (evaluate fold report)               | ×         | 70%      | critical 2 ×: found the bad "subsumed" claim via mutation but accepted the other 11 on the report's categorization; no per-function mapping |
| C (mutation harness)                   | ○         | 90%      | exit codes per suite, m1 flagged as import failure, sha256-verified restore; item 5 partial (per-suite command not shown in results.md)     |
| D (fold two functions; dev-principles) | ○         | 75%      | decision table enumerated all branches; differential check vs original; missing: test or note for participant-without-marker                |
| E (catalog owner; dev-principles)      | ○         | 100%     | followed README, flagged 2 deviating entries                                                                                                |

### Unclear points (Red)

- A: "The evaluator tests behavior; it does not read the implementation" — which implementation? Executor had to read gen.py to design the discriminating mutation
- A: "verify load-bearing claims" gives no criterion for what settles a "test X is subsumed by row Y" claim
- C: "whether it was detected" undefined; executor chose exit code non-zero, and separated import failure from assertion failure on its own
- D: "behavior must not change" vs path-escaping inputs ("", "a/b") — unclear whether a security quirk counts as behavior to preserve
- E: existing entries disagree; nothing ranks README over majority (executor picked README anyway)

### Conclusion from Red

- development-principles sentences (fold enumeration / convention over majority / trust-boundary input): **no Red in fixture** → not added. Fresh executors already do these; the real-world misses were the long main session's, not the text's
- C: **no Red in fixture** either → the "detector needs a positive completion signal" sentence has only the real-world incident as evidence; keep it as a candidate, decide after iteration 1
- A's critical 2 reproduces the real miss → iteration 1 targets it with the "load-bearing = enumerate before/after" sentence. C stays in the loop as a regression guard

## Iteration 1 (proposed-harness-workflow-v1.md pasted as superseding text)

### Changes

- harness: evaluator-of-tests sentence (break the subject, green proves nothing); load-bearing = counts/deletions/"no longer applies", enumerate before/after
- workflow: "never claim a fact without proof" widened from completion to any factual claim; detector needs a positive completion signal, record exit codes per case

| Scenario | Pass/Fail | Accuracy       | steps | notes                                                                                                     |
| -------- | --------- | -------------- | ----- | --------------------------------------------------------------------------------------------------------- |
| A        | ○         | 100% (Red 70%) |       | 12-row before/after mapping; 14 mutations incl. the discriminating one; remedy verified in a scratch copy |
| C        | ○         | 90%            |       | unchanged from Red; item 5 partial (command line paraphrased, not quoted)                                 |

### Unclear points (new)

- A, C: "does not read the implementation" vs "break the subject one rule at a time" pull in opposite directions; executors resolved as "read to design, exit codes decide"
- A: "rule" in "break one rule at a time" undefined
- C: "same message" does not map to a file deliverable
- C: "N passed line" absent when the run dies at collection; is exit 2 a completed run?
- C: "enumerate before/after" sentence does not apply when nothing is removed; executor wondered whether to force-fit it
- A: "case" in "exit codes per case" ambiguous (mutation vs mutation × suite)

### Discretionary fill-ins (new)

- A: binary verdict instead of "accept with required fix"; remedy verified in a scratch copy rather than editing the artifact under evaluation
- C: baseline run as precondition; exact-once OLD matching; bytecode-cache suppression

### Next fix (v2, same theme, wording only)

- resolve the read/break conflict: "may read the subject to design a check; the verdict comes from what ran"
- "one condition" instead of "one rule"; "place the command and its output next to the claim" instead of "same message"; define completion signal as exit code + runner summary; collection error = completed run with no test executed; "when nothing is removed, this does not apply"

## Iteration 2 (proposed-harness-workflow-v2.md: wording fixes, same theme)

| Scenario | Pass/Fail | Accuracy          | notes                                                                                                           |
| -------- | --------- | ----------------- | --------------------------------------------------------------------------------------------------------------- |
| C        | ○         | 100% (iter1 90%)  | m1 reported as "no test executed (not a pass, not a failure)"; harness command quoted; results.json + log       |
| A        | ○         | 100% (iter1 100%) | 12-row mapping; 12 mutants incl. the discriminating one; collection-error mutant reported as "no test executed" |

### Unclear points (new, from C)

- C: task asks binary detected/not; rule's third category ("no test executed") had to override the task framing — executor flagged it, resolved correctly
- C: "break one condition at a time" describes evaluating a suite; when mutations are given, unclear whether to author more (executor did not)
- C: "green proves nothing" vs equivalent mutant where green is correct — executor resolved by stating the diff is comment-only

### Unclear points (new, from A iter2)

- "one condition": does an equivalent-looking rewrite count? (executor tried one, found it equivalent, recorded as observation)
- whether merging alone (no removal) triggers enumeration — text says "removed or merged", executor applied to both; residual doubt only
- reading-to-design vs reading-to-judge boundary still called "fuzzy", but executor kept the verdict anchored to run output

### Convergence decision

- A: 70% → 100% → 100%; C: 90% → 90% → 100%. Both critical items met in iter1 and iter2
- New unclear points did not reach 0 in iter2, but they are definitional residue ("condition", "merged") rather than misreadings that changed behavior. Resource cutoff applied per the skill (shipping at this point is a valid call); residuals recorded here
- Hold-out B run with v2 text; result below

## Hold-out B (sealed; run once with v2)

| Scenario                     | Pass/Fail | Accuracy | notes                                                                                                                        |
| ---------------------------- | --------- | -------- | ---------------------------------------------------------------------------------------------------------------------------- |
| B (cluster names in PR body) | ○         | 100%     | identifiers labeled as such; -1 names from inventory; mapping stated as inference; integration flagged 要確認 (2 candidates) |

No overfitting: hold-out accuracy is at the loop's level. Residual unclear point from B: the rule tells you the mapping needs a second source but not what to do when none exists (executor wrote it as a labeled inference — acceptable fallback, left implicit).

## Shipped

- chezmoi source edited: `home/dot_claude/rules/harness-engineering.md`, `home/dot_claude/rules/workflow.md` (+8/-9 lines, bullets 159 → 158). Awaiting `chezmoi apply` confirmation.
- Not shipped (no Red in fixture): development-principles additions (fold enumeration / convention over majority / trust-boundary input). Deletion candidates there remain a separate budget decision.
- Agents used: 4 Red executors + 4 judges, 4 iteration executors + 4 judges, 1 hold-out executor + 1 judge, 2 reading checks = 20 (executors on session model, judges on sonnet).
