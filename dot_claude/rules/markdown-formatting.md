# Markdown Formatting

Language-independent formatting rules for Markdown output (responses, PR bodies, docs).

- Don't hardcode numbers at the start of headings or list items. If order matters, let
  Markdown's ordered-list syntax (`1.` `2.`) render the numbering; don't type the numerals
  into the body text yourself.

## Line breaks in prose: Semantic Line Breaks

Follow [Semantic Line Breaks](https://sembr.org/) for prose in Markdown files, both English and Japanese.
Soft breaks don't affect rendering; they exist for diffs and editing, so place them at semantic boundaries.

- One sentence per line (after 。．.！？!?) — this is the SemBr MUST level
- A long sentence may break after a major clause (、 semicolon, em dash) — never mid-clause to satisfy a column limit
- Multi-sentence list items: continuation lines also break per sentence
- Japanese extra caution: a mid-sentence wrap can render as a bogus half-width space (CSS segment-break removal for CJK is spec'd but unevenly implemented across browsers), so the sentence boundary is the only safe break point
- Where newlines are hard breaks, this rule does not apply: GitHub issue/PR comment bodies, tables, code blocks

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
