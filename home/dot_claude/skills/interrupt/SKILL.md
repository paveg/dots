---
name: interrupt
description: |
  Delegate an interrupt task to a background agent in an isolated worktree.
  The main session continues uninterrupted. The agent implements and commits; push and PR wait for the user's go-ahead.
  Use when a quick fix or small task needs to happen without losing current context.
argument-hint: Task description (e.g., "fix the null check in auth middleware")
---

# Interrupt Task

Delegate a task to a background agent running in an isolated git worktree. Your current session stays uninterrupted.

## Phase 1: Validate & Prepare

**Input**: $ARGUMENTS

1. If `$ARGUMENTS` is empty or vague, ask the user to clarify the task
2. Confirm you are in a git repository
3. Generate a branch name from the task description:
   - Slugify: lowercase, replace spaces/special chars with hyphens, max 50 chars
   - Prefix with `fix/` or `feat/` based on task nature
4. Show the user: branch name, base (current HEAD), and task summary
5. Proceed without waiting for confirmation (speed matters for interrupts)

## Phase 2: Launch Background Agent

Dispatch the `implementer` agent (it runs in the background; results arrive as a notification) with these parameters:

- `isolation: "worktree"` — runs in a fresh worktree copy
- `description` — short summary (3-5 words)

The agent prompt MUST include:

- The full task description
- Instruction to: implement the fix and make atomic commits on the new branch — never push, never create a PR (integration belongs to the main session)
- Instruction to keep changes minimal and focused
- The base: current HEAD, which the agent branches from (the PR target is confirmed at the push gate)

Example agent prompt structure:

```
You are working in an isolated git worktree. Your task:

{task description}

Steps:
1. Understand the codebase context (read CLAUDE.md, explore relevant files)
2. Create a new branch: {branch-name}
3. Implement the fix/feature with minimal, focused changes
4. Commit with a descriptive message
5. Run the project's tests/linters that exercise the change; capture the output
6. Do not push or open a PR
7. Final output: branch name, commit SHAs, verification output, and a proposed PR title and body
```

## Phase 3: Confirm & Continue

After launching the agent:

1. Tell the user the background task is running
2. Mention the branch name for reference
3. Remind them they'll be notified when it completes
4. Mention `git worktree list` if they want to check on it
5. **Resume the previous conversation context** — the whole point is zero interruption

When the background agent completes:

- Check placement: `git worktree list` and `git branch -v` show the main tree untouched and the new branch at the agent's commits
- Review the agent's diff and verification output as the evaluator
- Show the user the branch, a diff summary, and the proposed PR title/body, and ask before pushing or creating the PR (`workflow.md`: push and PR creation need explicit confirmation)
- After the PR exists or the user declines, remove the worktree with `git worktree remove <path>`
