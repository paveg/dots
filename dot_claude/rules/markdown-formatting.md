# Markdown Formatting

Language-independent formatting rules for Markdown output (responses, PR bodies, docs).

- Don't hardcode numbers at the start of headings or list items. If order matters, let
  Markdown's ordered-list syntax (`1.` `2.`) render the numbering; don't type the numerals
  into the body text yourself.

## Line breaks in prose

Outside code, soft line breaks carry no meaning — renderers join them. Break
only at semantically clean points; never mid-sentence to satisfy a column limit.

- Japanese: GitHub joins soft breaks **with a half-width space**, so a
  mid-sentence wrap injects a visible bogus space into the rendered text.
  Write one paragraph per line; for long paragraphs, breaking after 。 is fine
- List items: one item per line, no continuation-indent wrapping of Japanese
- English may keep conventional ~80-column wrapping (space-join is lossless)
- Where newlines DO matter, this rule does not apply: GitHub issue/PR comment
  bodies (single newline renders as a break), tables, code blocks

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
