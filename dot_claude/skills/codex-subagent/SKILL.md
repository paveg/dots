---
name: codex-subagent
description: |
  Delegate a bounded coding task to the local Codex CLI and return its result
  to Claude for verification and synthesis. Use whenever the user explicitly
  asks Claude to use, consult, or get a second opinion from Codex, and when a
  coding task calls for an independent cross-model investigation, review,
  plan, or clearly scoped implementation. For routine work Claude can finish
  directly, invoke this skill only when the user specifically requests Codex.
---

# Codex Subagent

Use Codex as a bounded worker. Claude remains the coordinator: choose the task, supply the context, verify the result, and communicate with the user.

## Dispatch workflow

1. Read `$ARGUMENTS` and the conversation. Define one concrete Codex task with a clear boundary and deliverable. If the user named several independent tasks, dispatch them separately; do not combine unrelated work into one vague prompt.
2. Choose the permission mode:
   - Use the default read-only mode for investigation, planning, explanation, code review, and second opinions.
   - Add `--write` only when the user explicitly requested implementation and Codex owns a clearly scoped set of changes. Do not let Claude and Codex edit the same files concurrently.
3. Describe the outcome and completion bar, then give only context and constraints that change the work. Include file paths or symbols already known; do not prescribe a detailed process or make Codex rediscover context Claude already has. Never copy secrets, credentials, or unrelated conversation history into the prompt.
4. Run the dispatcher once. It checks the CLI, applies the selected sandbox, adds the worker contract, uses an ephemeral Codex session, and prints only Codex's final report. It inherits the configured Codex model and reasoning effort; control those with Codex configuration rather than prose such as "think harder."

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/dispatch.sh" --cd "$PWD" <<'CODEX_TASK'
<goal>
State the user-visible outcome Codex should produce.
</goal>
<context>
State the user's intent, known relevant paths, and facts already established.
</context>
<success_criteria>
State what must be true before Codex can report completion, including validation.
</success_criteria>
<constraints>
State what is in scope, what must remain unchanged, and any evidence requirements.
</constraints>
<output>
State what Claude needs back: conclusions, path-and-line evidence, changes,
verification output, material risks, or blockers.
</output>
CODEX_TASK
```

For an explicitly requested implementation, add `--write` before `--cd` and name the files or subsystem Codex owns in `<constraints>`.

## Review the return

Treat Codex's report as peer work, not as automatically correct.

- Check cited files, lines, commands, and conclusions before relying on them.
- In write mode, inspect `git status --short` and `git diff`, confirm that pre-existing user changes were preserved, and run verification appropriate to the risk.
- Resolve disagreements using repository evidence. Report meaningful uncertainty instead of silently choosing one model's claim.
- Present a synthesized answer in Claude's voice. Identify Codex as a consulted subagent only when that provenance helps the user.

If the dispatcher returns a nonzero status, explain the concrete failure. Ask the user only for information or authority that neither Claude nor Codex can obtain safely.
