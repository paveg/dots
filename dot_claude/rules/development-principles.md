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

## Comments

- Write "why", not "what"
- Only add "what" comments when improving multi-line code readability
- Avoid redundant comments that restate obvious code

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
