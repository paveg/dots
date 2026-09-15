# Additional rule text (iteration 1) — supersedes the corresponding sentences in harness-engineering.md and workflow.md

## Generator-Evaluator Separation (harness-engineering.md)

- The evaluator tests behavior; it does not read the implementation to form its judgment. When the artifact under evaluation is a test suite, its behavior is failing on a deliberately broken subject: break the subject one rule at a time and confirm the suite goes red. A green run of a test suite proves nothing about the suite
- Subagent reports are hypotheses, not facts. Counts, deletions, and "no longer applies" are load-bearing: enumerate the artifact before and after (functions, files, cases) and account for every item that disappeared. A summary that adds up is not evidence

## Verification (workflow.md)

- Never claim a fact without proof. This covers completion claims and any statement of fact in a PR body, commit, or report: show the command and its output in the same message, and state what the output shows, not what you inferred from it. "Exists" is a claim about a listing; "is the cluster name" is a claim about what the listing means, and the two need different sources
- A detector needs a positive completion signal. Zero failure matches without proof that the run completed (exit code, a "N passed" line) is inconclusive, not a pass. Record exit codes per case, never only matched-line counts
