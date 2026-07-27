# Markdown Formatting

Language-independent formatting rules for Markdown output (responses, PR bodies, docs).

- Don't hardcode numbers at the start of headings or list items. If order matters, let Markdown's ordered-list syntax (`1.` `2.`) render the numbering; don't type the numerals into the body text yourself.

## Line breaks in prose

Prose has **no column limit** and is **not hard-wrapped** by default. Write one paragraph per line and let the editor/renderer soft-wrap. A hard wrap gains nothing in rendered Markdown (CommonMark collapses a soft break to a space) and is a footgun on hard-break surfaces (below).

- **Never wrap hard-break surfaces**: GitHub issue / PR / comment bodies render every single newline as a `<br>`, so a wrapped paragraph shows as jagged forced breaks. Write them as long unwrapped lines with a blank line between paragraphs. (Tables and code blocks are not prose — leave them.)
- **Follow the repo's prose convention when it declares one**: Prettier `proseWrap`, or an existing consistently-wrapped corpus (e.g. these rule files). Match it.
- [Semantic Line Breaks](https://sembr.org/) (one sentence per line) is **opt-in** — worth it only where the repo wants sentence-granularity prose diffs, never the global default. When wrapping, break only at sentence boundaries (。．.！？!?), never mid-clause. Japanese: a mid-sentence wrap can render as a bogus half-width space (CJK segment-break removal is unevenly implemented), so the sentence boundary is the only safe break.

**Code line length** is not governed here — it follows each language's own formatter / linter (`.editorconfig`, `.stylua.toml`, Prettier, `shfmt`, etc.), never a Markdown-wide column rule.

## Diagrams: mermaid in artifacts, ASCII in chat

Use mermaid in **written artifacts only** — PR bodies, ADRs, README, technical docs, .md files — where GitHub, Obsidian, VS Code preview, etc. render it as a real diagram. In chat/terminal responses it is the reverse: mermaid does not render there, so use ASCII art, prose, or short bullet lists instead.

### Authoring rules

- ≤ ~10 nodes per diagram; split larger into multiple
- Concrete node labels (`UserService`, not `ServiceA`)
- Show before/after side-by-side for structural refactors
- Prefer `LR` for pipelines, `TD` for hierarchies

For embedding in GitHub PR bodies safely (backslash-escape pitfall), see `gh-pr-body.md`.
