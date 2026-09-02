# Development Principles

## Simplicity

Read every file the change touches and trace the real flow end to end first. Then stop at the first rung that holds — the ladder shortens the solution, never the reading:

1. Does it need to exist? Speculative need → skip it and say so in one line
2. Already in this codebase? Reuse the helper, type, or pattern that is already here
3. Standard library does it? Use it
4. Native platform feature covers it (HTML element, CSS, DB constraint)? Check current platform docs before reaching for a package
5. An already-installed dependency solves it? Use it. Never add a dependency for what a few lines can do
6. Fits in one line? One line
7. Only then: the minimum code that works

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes, no scaffolding "for later"
- Do not add lines without explicit user request. Deletion over addition, boring over clever, fewest files
- Shortest working diff in the right place — the smallest change in the wrong place is a second bug
- Bug fix = root cause: grep every caller of the function you touch and fix the shared function once, not each caller
- Two same-size options → the one that is correct on edge cases. Less code, not the flimsier algorithm
- A deliberate simplification with a known ceiling (global lock, O(n²) scan, naive heuristic) gets a comment naming the ceiling and the upgrade condition
- Never simplify away: validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything explicitly requested
- Ship the lazy version and question the rest in the same reply; report `skipped: X, add when Y` in at most three lines

## Honesty

- Do not answer questions with actions

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

Explicitly forbidden (the rot-comment hook blocks task/PR refs, caller refs, and temporal phrasing mechanically):

- Repeating what the code does, restating the signature, or section banners
- Commented-out code (delete it; git remembers)
- Facts whose source of truth lives elsewhere — counts (tests, cases, callers, fields), lists of callers, versions, dates, ticket numbers, "what changed". They go stale the moment someone edits a different file. Living docs (README, CLAUDE.md, rules, skills) follow the same rule; point-in-time records (PR bodies, commit messages, worklogs) may carry them

## Command Legibility

Shell commands you run are audited by the user in real time. Optimize for "obvious at a glance," not cleverness.

- Avoid long pipe chains. When a one-liner chains more than ~3 stages (`|`), the user cannot tell what it does — split into separate steps, or write a short script and run that
- Prefer a dedicated tool (Read, Grep, Glob) over a `find | xargs | sed | awk` pipeline when one exists
- When a pipeline genuinely is the right tool (e.g. `… | jq …`), say in one line what it produces

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
