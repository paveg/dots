---
name: learning-primer
description: |
  Research a repo/docs in parallel for a given topic and generate a disposable
  GFM+mermaid learning primer (Markdown). Triggers (Japanese): 「〜の学習資料を作って」
  「オンボーディング資料がほしい」「〜をキャッチアップしたい」「primer 作って」.
  Output is not committed (defaults to repo-local `.ai/`, globally git-ignored);
  view with mo or any GFM+mermaid viewer.
argument-hint: <topic> <audience> [sources] [out]
---

# learning-primer

Research target repositories/docs in parallel for a topic and generate a
**disposable learning primer (Markdown, with mermaid diagrams)** tailored to the
reader. Domain-agnostic: never hardcode domain knowledge — research it from
`sources` each time.

Initial request: $ARGUMENTS

## Diagram-first (top priority)

Diagrams are the centerpiece. Use mermaid aggressively to maximize the reader's
comprehension and knowledge retention.

- **Any explanation involving structure, time order, relationships, or before/after gets a mermaid diagram** — do not settle for prose alone
- Aim for **at least one diagram per section** across skeleton §1–§4 (skip sections with no such structure)
- Give each diagram a one-line caption (what it shows) right before or after it, so it reads standalone
- One diagram = one concept. Show the `audience` before → after and the prerequisite Tier dependencies as diagrams too
- Do not cram — **split** instead (node cap and diagram types per "Mermaid diagram types" below)

## Inputs

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| `topic` | ✓ | — | Subject to learn |
| `audience` | ✓ | — | Reader profile; frame as "current state → target state" |
| `sources` | optional | cwd | Repos/dirs to research (multiple allowed) |
| `out` | optional | `.ai/<topic-slug>-primer.md` | Output path |

The default `out` lives in `.ai/`, which is **globally git-ignored**
(`~/.config/git/ignore`), so it is never committed. Override with `out=/tmp/...`
to write outside the repo. Outside a git repo where `.ai/` is not ignored, set
`out` explicitly.

**Early return**: if `topic` or `audience` is missing, ask for it. Do not guess.

## Procedure (research harness)

1. **Validate inputs**: confirm `topic` / `audience`; ask if missing (early return)
2. **Classify sources**: detect whether `sources` (default cwd) is a docs site / plain Markdown / code-only, and adapt
   > [!WARNING]
   > Landing / index / category pages are often **stubs**. Do not trust the index — read the real files (design docs, ADRs, how-tos, code).
3. **Decompose**: split `topic` into 3–5 sub-areas. Generic categories: concept & motivation / how it works / workflow & lifecycle / surrounding ecosystem & tools / prerequisites
4. **Parallel fan-out**: assign each sub-area to an Explore subagent; have it return **only "conclusion + evidence `path(:line)`"** (no long quotations — preserve main context)
5. **Synthesize**: pour into the skeleton below. Open with the `audience` before → after to create the perspective shift
6. Pass the **quality gates** (below)
7. **Write** to `out` (create `.ai/` if absent). Finish by presenting the viewer command `mo <out>`. Installs (brew/npm/gh ext, etc.) need network — delegate to the user; automate only generation (file write) and localhost viewing

## Output skeleton (fixed)

Write the primer in the audience's language; translate the headings accordingly.

```
# <topic> Learning Primer (for <audience>)
0. Mindset (current → target / perspective-shift table)
1. Big picture and the "why" + diagram
2. Components & related repos/tools map + diagram
3. Workflow / lifecycle + diagram
4. Sub-area deep dives (structure/relationship diagram per area)
5. Prerequisites (Tier 1/2/3 table + dependency diagram)
6. What to read (source paths, by priority)
7. First steps (concrete actions)
Appendix: glossary (optional)
```

### Mermaid diagram types (derive from content; one per concept, ~4–8 total)

| Purpose | Syntax |
|---------|--------|
| Structure/dependency, before/after | `graph TD` |
| Data flow / pipeline | `flowchart LR` |
| Lifecycle / phases | `stateDiagram-v2` |
| Cross-system calls | `sequenceDiagram` |
| Schema / relationships | `erDiagram` |

≤ ~10 nodes per diagram; concrete labels (no `ServiceA` — use `UserService`).

### Output format constraints (viewer-independent)

- Mermaid only in ` ```mermaid ` fences (no image/HTML embeds)
- Notes use GitHub Alerts (`> [!NOTE]` etc.); `:::note` and MDX-specific syntax are forbidden
- Tables, task lists, footnotes: GFM standard only; no frontmatter
- → renders intact in mo, GitHub, and VS Code (with extension)

## Quality gates (anti-slop)

- **Fact-grounding**: attach `path(:line)` to every non-obvious claim. If you cannot cite it, do not write it
- **Generator ≠ evaluator**: after generation, have a **separate subagent** do one pass flagging ungrounded or wrong claims (Generator-Evaluator separation from `harness-engineering.md`). The evaluator verifies grounding, not implementation
- **Honest coverage**: when prioritizing from a large set, state "read M of N; reverse-lookup recommended for the rest" (no silent truncation)
- **Absolute dates**: no "recently" — use `YYYY-MM-DD`

## General lessons (what actually helps)

- **Don't trust landing/index pages**: often heading stubs. Read the real files
- **Don't win by volume**: sort large doc sets (e.g. ADRs) by date/importance and prioritize "foundational → specific". Distinguish old foundational decisions from recent one-off ones hit in operations
- **Verify external tools' real capabilities**: outcomes diverge on things like a renderer's mermaid support. Verify before recommending — do not guess
- **The reader's current state is the strongest hook**: framing `audience` as before → after gives a foothold for understanding
- **State environment constraints**: installs (network) are delegated to the user; automate only generation (write) and localhost viewing
