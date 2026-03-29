---
alwaysApply: true
---

# Development Principles

## Test-Driven Development

- See `tdd.md` for detailed TDD rules

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
