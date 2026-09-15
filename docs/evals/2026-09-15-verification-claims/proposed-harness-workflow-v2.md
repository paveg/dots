# Additional rule text (iteration 2) — supersedes the corresponding sentences in harness-engineering.md and workflow.md

## Generator-Evaluator Separation (harness-engineering.md)

- The evaluator judges by behavior, not by reading the implementation: it may read the subject to design a check (which rule to break, which input to feed), but the verdict comes from what ran and what it returned. When the artifact under evaluation is a test suite, its behavior is failing on a deliberately broken subject: break one condition of the subject at a time and confirm the suite goes red. A green run of a test suite proves nothing about the suite
- Subagent reports are hypotheses, not facts. Counts, deletions, and "no longer applies" are load-bearing: when items are removed or merged, enumerate them before and after and account for every one; a summary that adds up is not evidence. When nothing is removed, this does not apply

## Verification (workflow.md)

- Never claim a fact without proof. This covers completion claims and any statement of fact in a PR body, commit, report, or file you produce: place the command and its output next to the claim, and state what the output shows, not what you inferred from it. "Exists" is a claim about a listing; "is the cluster name" is a claim about what the listing means, and the two need different sources
- A detector needs a positive completion signal: an exit code plus the runner's own summary line (passed / failed / error counts). Zero failure matches without that signal is inconclusive, not a pass. A collection or import error is a completed run that says "no test executed"; report it as such, not as a failure or a pass
