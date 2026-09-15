# Additional rule text (Green) — supersedes the corresponding sentences in development-principles.md

## Simplicity

- Already in this codebase? Reuse the helper, type, or pattern that is already here. When existing instances disagree, the declared convention (README, schema, lint) wins over the majority of instances; note the drift
- Two same-size options → the one that is correct on edge cases. When collapsing branches into one predicate, list the inputs each branch alone accepted and check that the merged predicate still accepts every one of them before deleting the branch
- Never simplify away: validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything explicitly requested. An external input (CLI flag, environment variable, file name) that selects the target of a destructive or privileged operation is checked against the authority before use; adding that check is not "adding lines"
