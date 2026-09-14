# Database Safety

A PreToolUse Bash hook (`block-destructive-db.sh`) denies known destructive database commands (`db:reset`, `prisma migrate reset`, `TRUNCATE`, `DROP DATABASE`, …) regardless of test-environment markers: `NODE_ENV=test` does not prove which datasource a framework or raw client will target. The judgment the hook cannot make:

- Never wipe a database to recover from a transient error (concurrent-test schema noise, flaky migrations, stale fixtures). A reset destroys dev data that lives in no seed or snapshot
- On schema/DDL errors: stop, capture the exact error and command, report with that evidence, and wait for instruction. Whether a reset is acceptable is the user's call
- Never build a destructive database command from parameter, brace, glob, or runtime expansion. The hook matches known literal patterns only; it is an advisory guard, not a shell evaluator
- The hook may match a database runner plus destructive text across shell control operators. A diagnostic that only prints or searches those strings goes in a separate Bash call
- To run a destructive command deliberately, the user runs it in their own shell (the hook only sees tool-invoked commands), or adds a narrowly scoped allow rule for that command in the project's `.claude/settings.json`
