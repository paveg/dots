---
alwaysApply: true
---

# Mermaid Diagrams

Use mermaid in **written artifacts only** — PR bodies, ADRs, README, technical docs, .md files. These are rendered as proper diagrams by GitHub, Obsidian, VS Code preview, etc.

Do not use mermaid in chat / terminal responses. The terminal cannot render mermaid as a real diagram, and ASCII fallbacks add noise without aiding comprehension. For in-conversation explanations, use prose, ASCII tables, or short bullet lists.

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
