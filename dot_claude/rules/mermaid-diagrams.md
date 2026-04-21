---
alwaysApply: true
---

# Mermaid Diagrams

Actively use mermaid when explaining architecture, flow, sequences, or state. A small diagram beats a paragraph of prose.

## Reach for mermaid in

- Design / brainstorming responses — align on shape before implementation
- PR bodies describing structural or cross-system changes
- ADRs and technical docs

## Type by use case

| Use case | Syntax |
|----------|--------|
| Architecture / dependency | `graph TD` |
| API / cross-system calls | `sequenceDiagram` |
| State machines, lifecycles | `stateDiagram-v2` |
| Data flow / pipeline | `flowchart LR` |
| Schemas / relations | `erDiagram` |

## Rules

- ≤ ~10 nodes per diagram; split larger into multiple
- Concrete node labels (`UserService`, not `ServiceA`)
- Show before/after side-by-side for structural refactors
- Prefer `LR` for pipelines, `TD` for hierarchies

## Terminal rendering constraints (mermaid-ascii)

A Stop hook auto-renders ```` ```mermaid ```` blocks as ASCII in my terminal via [mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii). To keep renders clean, author diagrams within its limits:

- **Decision nodes:** use `[label]` not `{label}` — curly-brace diamonds break silently (label appears as a separate node)
- **Supported types:** `graph TD/TB/LR`, `flowchart TD/TB/LR`, `sequenceDiagram` — rendered inline
- **Unsupported types:** `stateDiagram-v2`, `erDiagram`, and others — the raw mermaid source is still shown; switch to `graph TD` if visualization matters, otherwise accept the raw text

For embedding in PR bodies safely (backslash-escape pitfall), see `gh-pr-body.md`.
