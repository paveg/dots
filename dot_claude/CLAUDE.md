# Global Configuration

This is the global CLAUDE.md. Rules are organized in `~/.claude/rules/`.

## Codex delegation

For every non-trivial coding task, use the `codex-subagent` skill when Codex can own a bounded investigation, review, plan, or implementation workstream. Keep only trivial single-step work inline. Claude remains the coordinator: define the scope, prevent overlapping edits, verify Codex's evidence and changes, and synthesize the result for the user.
