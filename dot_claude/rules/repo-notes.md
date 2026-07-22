# Repository Notes (.ai/)

`.ai/` at the repo root is the USER's local note pile, written as Markdown (globally git-ignored; never committed). It is not Claude's memory.

- At the start of work on a repo, skim the relevant `.ai/*.md` for context
- What goes there:
  - Material FOR the user's learning (learning-primer output, requested study notes, glossary) — one topic per file, kebab-case names
  - Work logs under `.ai/worklog/YYYYMMDD.md` (e.g. daily-kickoff skill output)
  - Detailed write-ups of non-trivial investigations Claude performed (sources checked, commands run, findings, dead ends) — one topic per file, kebab-case names. Write these proactively when an investigation took multiple sources or produced conclusions worth re-reading
- Division of labor with persistent memory: memory holds the compact durable fact (one file, one fact); `.ai/` holds the detail behind it. Link the memory to the `.ai/` file path when both exist
- No secrets, no facts the code/git already records
