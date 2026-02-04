---
alwaysApply: true
---

# PR/Commit Size Guidelines

## Principles

- Create PRs in the **smallest shippable unit**
- Keep changes reviewable in a single sitting

## Size Targets

| Language | Warning | Consider Splitting |
|----------|---------|-------------------|
| Ruby/TS  | 400 LOC | 600 LOC           |
| Go/Java  | 600 LOC | 1000 LOC          |

**Effective logic** (excluding generated code and test data) should stay **under 300 LOC**.

## When to Split

- Multiple independent functional changes in one PR
- Review would take over an hour

## Commit Granularity

1 commit = 1 logical change (target 100-200 LOC)

## When a PR Is Unavoidably Large

Include in the PR description:
- Total LOC changed / effective logic LOC
- Which parts are core changes (need careful review) vs mechanical changes (skim OK)
