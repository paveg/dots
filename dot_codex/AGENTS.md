# AGENTS.md

Personal global instructions for Codex, managed by chezmoi. Keep this file lean: Codex caps the combined instruction set at 32 KiB and loads this global file first, so a fat global crowds out repo-level AGENTS.md. Aim for ≤5 KiB.

## Command Legibility

Shell commands you run are audited by the user in real time. Optimize for "obvious at a glance," not cleverness.

- Avoid long pipe chains. When a one-liner chains more than ~3 stages (`|`), the user cannot tell what it does — split it into separate steps, or write a short script and run that.
- Prefer a single focused command over a sprawling `find | xargs | sed | awk` pipeline when a simpler form exists.
- When a pipeline genuinely is the right tool (e.g. `… | jq …`), say in one line what it produces.

## Shared Claude skills

`~/.agents/skills` links to `~/.claude/skills`. Treat those skills as shared workflows. When one names a Claude-specific surface, preserve its workflow and translate it to the equivalent Codex capability:

- `Agent` or subagent dispatch → Codex collaboration subagents, including the requested fan-out and isolation when available.
- `TaskCreate` / `TaskUpdate` → the Codex plan; `AskUserQuestion` → a concise user question; `Monitor` / `TaskStop` → available monitoring or session controls.
- `${CLAUDE_SKILL_DIR}` → the directory containing the selected `SKILL.md`.

If no equivalent capability exists, state the gap and use a safe inline fallback only when it preserves required separation and isolation. Never invoke `codex-subagent` from inside Codex; it is the Claude-to-Codex bridge.
