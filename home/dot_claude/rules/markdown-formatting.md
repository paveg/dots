# Markdown Formatting

Language-independent rules for Markdown output (responses, PR bodies, docs).

- Don't type numerals into headings or list items. If order matters, use ordered-list syntax (`1.` `2.`) and let Markdown render the numbering

## Line breaks in prose

- Prose has **no column limit** and is **not hard-wrapped**: one paragraph per line, soft-wrapped by the renderer. CommonMark collapses a soft break to a space, so wrapping gains nothing
- **Never wrap GitHub issue / PR / comment bodies**: every newline renders as `<br>`. Tables and code blocks are not prose
- Follow the repo's declared prose convention (Prettier `proseWrap`, a consistently wrapped corpus) when there is one. [Semantic Line Breaks](https://sembr.org/) are opt-in per repo, never the default; when wrapping, break only at sentence boundaries (。．.！？!?), since a mid-sentence wrap in Japanese can render a bogus half-width space
- Code line length follows each language's own formatter, never a Markdown rule

## Diagrams: mermaid in artifacts, ASCII in chat

Use mermaid only in written artifacts (PR bodies, ADRs, README, `.md` files) where GitHub, Obsidian, or VS Code render it. Chat/terminal responses do not render it: use ASCII art, prose, or short bullets there.

### When to diagram

A diagram is due when prose would make the reader sketch it themselves:

| Signal in the content                     | Diagram                 |
| ----------------------------------------- | ----------------------- |
| ≥3 participants exchanging calls/messages | `sequenceDiagram`       |
| ≥4 states in a transition                 | `stateDiagram-v2`       |
| Structural before/after comparison        | two graphs side by side |
| Procedure of ≥5 steps containing branches | `flowchart`             |

### Authoring rules

≤ ~10 nodes per diagram (split larger ones); concrete node labels (`UserService`, not `ServiceA`); `LR` for pipelines, `TD` for hierarchies. For embedding in GitHub PR bodies safely, see `gh-pr-body.md`.
