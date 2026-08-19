# 0007. Consolidate generation skills into one `writing` skill

## Status

Accepted — 2026-08-19. Partially revises the "Thin wrappers, unchanged boundaries" decision in [ADR 0002](0002-writing-skill-knowledge-consolidation.md); applies the naming convention of [ADR 0003](0003-skill-naming-convention.md).

## Context

ADR 0002 consolidated the duplicated writing knowledge into `references/japanese-writing/norms.md` but kept three skills separate: `technical-writing`, `article-writing`, `japanese-ai-writing-proofreader`. The user now wants to stop routing invocations by genre — one writing entry point instead of remembering which generator to call.

Decomposing ADR 0002's reasoning shows which parts still bind:

- Knowledge dedup into norms: done, unaffected.
- Generation ↔ verification is a hard line: still valid — an invocation that grades its own output violates generator-evaluator separation, and the proofreader has a standalone use (校正して on user-written text).
- "technical-writing and article-writing are different workflows, therefore separate skills": the premise is true but the conclusion no longer follows. A thin router SKILL.md with per-mode detail in `references/` loaded just-in-time keeps the workflows distinct while collapsing the invocation surface. Two always-on skill descriptions become one, which also serves the standing context-efficiency constraint.

## Decision

- Merge `article-writing` + `technical-writing` into one skill named **`writing`**: a thin router SKILL.md; mode-specific material (article phases, fact-check gate, style profiles; technical-doc tactics) moves to `references/` and loads only for the selected mode.
- Mode is auto-detected from the artifact destination: repository file → technical-document mode; public platform → article mode with the fact-check gate. Ask the user only when ambiguous; never route by asking first.
- The proofreader **stays a separate skill** and is renamed **`writing-proofread`**, so the family clusters under the `writing-*` stem per ADR 0003. ADR 0003's lazy migration fires now because this change substantively touches the skill; every cross-reference (generator pointers, hooks, memory, CLAUDE.md mentions) moves in the same change.
- Workflow-specific skills (`pr-description`, `x-post-craft`, `daily-kickoff`, …) are out of scope: they are distinct workflows, not genre routing, and folding them in would bloat the router.

## Consequences

- One trigger surface for document generation; the always-on skill list shrinks by one description and the `writing-*` family sorts adjacently.
- The rename is a breaking cutover (skills have no aliases): invocation habits and all cross-references break unless swept in the same PR. The memory index entry referencing `article-writing` must be updated.
- Router quality becomes load-bearing: a misrouted mode silently skips the fact-check gate, so destination detection errs toward asking when ambiguous.
- Over-stripping risk carried over from ADR 0002: move mode material wholesale into references; the router itself stays free of restated norms.
- ADR 0002's done criterion "three wrappers" is superseded for the generators; its generator-evaluator boundary and norms-single-home criteria remain in force.
