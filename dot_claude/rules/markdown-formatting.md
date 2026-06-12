# Markdown Formatting

Language-independent formatting rules for Markdown output (responses, PR bodies, docs).

- Don't hardcode numbers at the start of headings or list items. If order matters, let
  Markdown's ordered-list syntax (`1.` `2.`) render the numbering; don't type the numerals
  into the body text yourself.

## Diagrams: mermaid in artifacts, ASCII in chat

Use mermaid in **written artifacts only** — PR bodies, ADRs, README, technical docs,
.md files — where GitHub, Obsidian, VS Code preview, etc. render it as a real diagram.
In chat/terminal responses it is the reverse: mermaid does not render there, so use
ASCII art, prose, or short bullet lists instead.

### Authoring rules

- ≤ ~10 nodes per diagram; split larger into multiple
- Concrete node labels (`UserService`, not `ServiceA`)
- Show before/after side-by-side for structural refactors
- Prefer `LR` for pipelines, `TD` for hierarchies

For embedding in GitHub PR bodies safely (backslash-escape pitfall), see `gh-pr-body.md`.
