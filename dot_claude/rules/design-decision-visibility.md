# Design Decision Visibility

Prevent AI slop from silently applied "better practices". Make implicit design
decisions visible so that humans retain decision-making authority.

- **Best practice** — optimal in virtually all contexts (prepared statements,
  never store plaintext passwords): apply silently without confirmation
- **Better practice** — generally recommended but context-dependent (error
  handling strategy, pagination, caching, state management): never apply
  silently; state why that choice was made and present alternatives
- When uncertain which of the two it is, treat it as a better practice and confirm

Before implementation: list decisions where multiple options exist, present
tradeoffs (organized by layer when they span infrastructure / application / UX),
and obtain user confirmation before proceeding.

After implementation: list design decisions implicitly made in the code,
classify each as best or better practice, and give the rationale for
better-practice choices in the current project context.
