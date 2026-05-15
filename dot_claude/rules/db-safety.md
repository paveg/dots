# Database Safety

## Never wipe a database to recover from a transient error

Commands like `db:reset`, `db:drop`, `db:setup`, `db:schema:load`, `prisma migrate reset`, `manage.py flush`, `TRUNCATE`, and `DROP DATABASE` wipe data unconditionally. They are virtually never the right response to:

- Concurrent-test schema noise (e.g. "Table definition has changed, please retry transaction")
- Flaky migrations that succeed on retry
- Stale fixtures, snapshot mismatches, or seed-cache drift

These look like "DB is broken, reset it" but are environment problems. Reset destroys whatever development data the human was relying on for manual testing, and that data is often not in any seed or snapshot.

## Stop, do not "recover"

When you see schema/DDL errors during tests or runtime:

1. Stop the destructive plan
2. Capture the exact error and the command that produced it
3. Report to the parent / user with that evidence
4. Wait for instruction

The user can decide whether a reset is acceptable — they know what dev data they have. You do not.

## Force the test environment explicitly

If you are running tests, set the test environment in the same command, not as inherited state:

- Rails / Rake: `RAILS_ENV=test bundle exec rails ...`
- Node / Prisma: `NODE_ENV=test ...`
- Elixir / Mix: `MIX_ENV=test ...`
- Django: `DJANGO_SETTINGS_MODULE=...test ...`

Inheriting environment from the parent shell is how "test cleanup" wipes development.

## Mechanical guard

A PreToolUse Bash hook denies destructive database operations by default unless the command explicitly opts into a test environment (`RAILS_ENV=test`, `NODE_ENV=test`, `MIX_ENV=test`). To run a destructive command deliberately:

- Run it in your own shell (the guard only blocks tool-invoked commands), or
- Add a per-project allow rule in `.claude/settings.json` for the specific pattern

The guard is conservative on purpose. A false-positive (one extra prompt) is cheap; a false-negative (wiping a developer's local DB) is hours of recovery.
