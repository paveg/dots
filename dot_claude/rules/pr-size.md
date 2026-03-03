---
alwaysApply: true
---

# PR Size

## The One Rule

Effective logic (excluding generated code, tests, data) per PR: **≤ 300 LOC**.

## Before Creating a PR, Ask:

1. Is effective logic ≤ 300 LOC?
   - YES → proceed
   - NO → split independent changes into separate PRs
2. Does this PR serve a single "why"? (1 PR = 1 purpose)
   - Multiple purposes → split
3. Unavoidably large → label core changes vs mechanical changes in the PR description

## Commit Granularity

1 commit = 1 logical change (100-200 LOC)
