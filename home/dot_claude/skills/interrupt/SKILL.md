---
name: interrupt
description: |
  Delegate an interrupt task to a background agent in an isolated worktree.
  The main session continues uninterrupted. The agent implements, commits, pushes, and creates a PR.
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

Launch an Agent with these parameters:

- `isolation: "worktree"` — runs in a fresh worktree copy
- `run_in_background: true` — does not block the main session
- `description` — short summary (3-5 words)

The agent prompt MUST include:

- The full task description
- Instruction to: implement the fix, make atomic commits, push the branch, create a PR via `gh pr create`
- Instruction to keep changes minimal and focused
- The base branch to target for the PR (usually `main`)

Example agent prompt structure:

```
You are working in an isolated git worktree. Your task:

{task description}

Steps:
1. Understand the codebase context (read CLAUDE.md, explore relevant files)
2. Create a new branch: {branch-name}
3. Implement the fix/feature with minimal, focused changes
4. Commit with a descriptive message
5. Push the branch: git push -u origin {branch-name}
6. Create a PR: gh pr create --title "{title}" --body "{body}"
7. Report the PR URL as your final output
```

## Phase 3: Confirm & Continue

After launching the agent:

1. Tell the user the background task is running
2. Mention the branch name for reference
3. Remind them they'll be notified when it completes
4. Suggest `wt ls` to see active worktrees if they want to check on it
5. **Resume the previous conversation context** — the whole point is zero interruption

When the background agent completes:

- Report the PR URL to the user
- Suggest cleanup: `wt rm {name}` or let the worktree auto-cleanup
