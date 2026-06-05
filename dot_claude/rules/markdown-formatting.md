---
alwaysApply: true
---

# Markdown Formatting

Language-independent formatting rules for Markdown output (responses, PR bodies, docs).

- Don't hardcode numbers at the start of headings or list items. If order matters, let
  Markdown's ordered-list syntax (`1.` `2.`) render the numbering; don't type the numerals
  into the body text yourself.
- In rendered Markdown (PR bodies, ADRs, README, docs), ASCII-art diagrams break — use
  Mermaid for structural diagrams instead. In chat/terminal it is the reverse: ASCII art
  is fine since Mermaid does not render there. See [mermaid-diagrams.md](mermaid-diagrams.md).
