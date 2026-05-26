---
alwaysApply: true
---

# Development Principles

## Simplicity

- Less code is better code
- Do not add lines without explicit user request
- Avoid over-engineering and premature abstraction
- Find root causes — no temporary fixes. Senior developer standards
- Changes should only touch what's necessary. Avoid introducing bugs

## Modern Practices

- Use latest language features and idioms
- Prefer modern libraries over legacy alternatives
- Stay current with ecosystem best practices

## Honesty

- Do not answer questions with actions
- Do not speculate on specifications — ask or investigate
- Admit uncertainty rather than guessing

## Readability

Code is read far more often than it is written. Optimize for the reader.

- **Naming is documentation**: variable, function, class, and module names must reveal intent without requiring a comment. Prefer `remainingRetryCount` over `cnt`, `fetchUserProfile` over `getData`
- Avoid abbreviations unless they are universal in the domain (`id`, `url`, `http`, `db` are fine; `usr`, `cnt`, `mgr` are not)
- Boolean names should read as assertions: `isVisible`, `hasPermission`, `shouldRetry`
- Functions should describe **what** they do, not **how**: `sortByCreatedAt` over `quickSortImpl`
- Scope rule: the wider the scope, the more descriptive the name. Single-letter names are acceptable only in trivial lambdas or loop indices

## Comments

Default: **no comments**. Only add a comment when ALL of the following are true:

1. The **why** is non-obvious (hidden constraint, subtle invariant, workaround for a specific bug)
2. Removing the comment would leave a future reader confused
3. The information cannot be conveyed by better naming alone

Explicitly forbidden:
- Repeating what the code does (`// increment counter`)
- Referencing the current task, PR, or issue (`// added for #123`)
- Multi-line docblocks that restate the function signature
- Section banners (`// --- Helper Functions ---`)
- Commented-out code (delete it; git remembers)

## Database Migrations

- Never hand-write migration files (SQL, meta, journal)
- Always generate via ORM migration CLI (e.g., `drizzle-kit generate`)
- Commit generated files as-is without manual edits
- Never manually create or edit ORM-managed metadata (snapshots, journals)

## Volatility Resistance

The output of a single prompt is volatile; the procedure that produced it is not. Invest in what survives the session boundary.

- Optimize for reproducible procedure, not one-shot prompt quality
- Spend time on artifacts that persist across sessions: specs, contracts, tests, harness rules, ADRs
- "A prompt that worked once" is not knowledge — capture the conditions that made it work, or it does not transfer
- When a session produces a good result through ad-hoc steering, distill the steering into a rule, hook, or skill before the lesson decays
