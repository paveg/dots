# AGENTS.md

Personal global instructions for Codex, managed by chezmoi. Keep this file
lean: Codex caps the combined instruction set at 32 KiB and loads this global
file first, so a fat global crowds out repo-level AGENTS.md. Aim for ≤5 KiB.

## Command Legibility

Shell commands you run are audited by the user in real time. Optimize for
"obvious at a glance," not cleverness.

- Avoid long pipe chains. When a one-liner chains more than ~3 stages (`|`),
  the user cannot tell what it does — split it into separate steps, or write a
  short script and run that.
- Prefer a single focused command over a sprawling `find | xargs | sed | awk`
  pipeline when a simpler form exists.
- When a pipeline genuinely is the right tool (e.g. `… | jq …`), say in one
  line what it produces.
