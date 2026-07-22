# model-profiles/

Swappable per-model prompting profiles. Inert reference data — not a rule or skill, so it adds no always-on context tax. Skills load the profile matching the session model on demand.

## What a profile is

A distilled, machine-actionable diff of how agent-facing config (CLAUDE.md, rules, skills, task prompts) should change for one model: what scaffolding to Remove, what to Rewrite, what to Keep/add. Model-specific facts live here; model-agnostic writing hygiene stays in the consuming skill.

## Consumers

- `claude-md-layout` — designs directory-level CLAUDE.md
- `empirical-prompt-tuning` — reviews/improves skills and prompts

Both open by loading `~/.claude/references/model-profiles/<session-model-id>.md`. If no exact match, fall back to the nearest same-family profile and note the gap.

## Updating (the anti-obsolescence contract)

- New model → copy `_template.md` to `<model-id>.md`, fill the three tables.
- Source doc changed → edit that one file. Nothing in the skills changes.
- Never hardcode a model's quirks in a skill body — that spreads the rot across every skill on the next upgrade. One file is the only place a model is named.
