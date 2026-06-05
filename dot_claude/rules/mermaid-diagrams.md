---
alwaysApply: true
---

# Mermaid Diagrams

Use mermaid in **written artifacts only** — PR bodies, ADRs, README, technical docs, .md files. These are rendered as proper diagrams by GitHub, Obsidian, VS Code preview, etc.

Do not use mermaid in chat / terminal responses — the terminal cannot render it as a real diagram. There, ASCII art (diagrams and tables), prose, or short bullet lists are the right tools.

## Where to use

- PR bodies describing structural / cross-system changes
- ADRs documenting architectural decisions
- README architecture / data-flow diagrams
- Technical specs and design docs

## Type by use case

| Use case | Syntax |
|----------|--------|
| Architecture / dependency | `graph TD` |
| API / cross-system calls | `sequenceDiagram` |
| State machines, lifecycles | `stateDiagram-v2` |
| Data flow / pipeline | `flowchart LR` |
| Schemas / relations | `erDiagram` |

## Authoring rules

- ≤ ~10 nodes per diagram; split larger into multiple
- Concrete node labels (`UserService`, not `ServiceA`)
- Show before/after side-by-side for structural refactors
- Prefer `LR` for pipelines, `TD` for hierarchies

For embedding in GitHub PR bodies safely (backslash-escape pitfall), see `gh-pr-body.md`.
