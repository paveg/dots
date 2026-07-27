# Database Safety

A PreToolUse Bash hook (`block-destructive-db.sh`) denies known destructive database commands (`db:reset`, `prisma migrate reset`, `TRUNCATE`, `DROP DATABASE`, …) regardless of test-environment markers. Generic markers such as `NODE_ENV=test` do not prove which datasource a framework or raw client will target. The rules below cover the judgment the hook cannot make.

- Never wipe a database to recover from a transient error (concurrent-test schema noise, flaky migrations, stale fixtures). These are environment problems; a reset destroys dev data that lives in no seed or snapshot.
- On schema/DDL errors: stop the destructive plan, capture the exact error and command, report with that evidence, and wait for instruction. Whether a reset is acceptable is the user's call — they know what dev data they have.
- Never construct a destructive database command dynamically with parameter, brace, glob, or runtime data expansion. The hook recognizes known literal patterns and simple quote/backslash concatenation; it is an advisory guard, not a shell AST/dataflow evaluator.
- The guard may conservatively match a database runner and destructive task text across shell control operators. If a diagnostic only needs to print or search those strings, issue it as a separate Bash call.
- A test marker does not bypass the hook. To run a destructive command deliberately, run it in your own shell (the hook only blocks tool-invoked commands), or add a narrowly scoped per-project allow rule in `.claude/settings.json` for the specific command.
