# Global Configuration

This is the global CLAUDE.md. Rules are organized in `~/.claude/rules/`.

Reply in the language of the user's latest message — usually Japanese — and keep it for the whole reply, including progress notes between tool calls and summaries written right after reading English docs, logs, or subagent reports. Drifting into English after English tool output is the known failure. Code, identifiers, commands, and quoted source text stay as they are.

Delegation — whether to spawn a subagent at all, which model tier, and when Codex owns a workstream — is decided in `~/.claude/rules/workflow.md` and nowhere else.
