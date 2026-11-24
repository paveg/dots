# User Notes (~/.local/share/agent-notes/)

`~/.local/share/agent-notes/` is the USER's local Markdown note pile, kept outside every repo so it is never committed or scattered across repos. It is not Claude's memory, and other agents do not read it: knowledge meant for any agent goes in committed CLAUDE.md / AGENTS.md or an ADR, and Claude's own lessons go in persistent memory.

- Write there only when the user asks (requested study notes, an investigation write-up, learning-primer output)
- Layout (one topic per file, kebab-case names):
  - learning-primer output: `primers/<topic>-primer.md`, whatever repo it covers
  - Other notes about the current repo's code or history: `<host>/<owner>/<repo>/<topic>.md`, taken from the `origin` URL (`github.com/paveg/dots/`); without an `origin` remote, use `local/<main checkout's directory name>/`
  - Everything else: `topics/<topic>.md`
- Read the repo's folder when the user points to it or when tracing past decisions (code-rationale)
- No secrets, no facts the code/git already records
- Legacy `.ai/` directories still exist at the root of a repo's main checkout (git-ignored, so absent from linked worktrees). Read them on request or when tracing past decisions; never add to them
