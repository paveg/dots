# Database Safety

A PreToolUse Bash hook (`block-destructive-db.sh`) denies destructive database commands (`db:reset`, `prisma migrate reset`, `TRUNCATE`, `DROP DATABASE`, …) unless the command explicitly opts into a test environment. The rules below cover the judgment the hook cannot make.

- Never wipe a database to recover from a transient error (concurrent-test schema noise, flaky migrations, stale fixtures). These are environment problems; a reset destroys dev data that lives in no seed or snapshot.
- On schema/DDL errors: stop the destructive plan, capture the exact error and command, report with that evidence, and wait for instruction. Whether a reset is acceptable is the user's call — they know what dev data they have.
- Set the test environment in the same command (`RAILS_ENV=test`, `NODE_ENV=test`, `MIX_ENV=test`, …) — inherited shell env is how "test cleanup" wipes development.
- To run a destructive command deliberately: run it in your own shell (the hook only blocks tool-invoked commands), or add a per-project allow rule in `.claude/settings.json` for the specific pattern.
