---
name: issue-ship
description: >
  Ship a GitHub Issue end-to-end: fetch the issue as the spec, implement via a
  worktree-isolated subagent, open a PR that closes the issue, then watch CI
  through merge. GitHub Issues is the single source of truth.
argument-hint: <issue-number> [--plan]
arguments: [issue]
disable-model-invocation: true
---

# Issue Ship

```
/issue-ship 123          # fetch → implement → PR (gated) → CI watch → close
/issue-ship 123 --plan   # plan-mode approval gate before implementation
```

## Invariants

- GitHub Issues is the only tracker in this loop. Never read from or write to
  any other issue tracker inside this workflow — that boundary is human-owned.
- The issue body is the spec. If it is too thin to implement from, ask the
  user; do not guess requirements.
- The first push / PR creation requires explicit user confirmation. Follow-up
  pushes to the same, already-approved PR (CI fixes) do not.
- The main session is the evaluator; it never writes the implementation itself.

## Steps

### 1. Fetch the issue

```bash
gh issue view $issue --json number,title,body,labels,assignees,state,url
```

- No argument → ask which issue to ship.
- `state` is `CLOSED` → report and stop.

### 2. Claim it

```bash
gh issue edit $issue --add-assignee @me
```

Fail-soft: if assignment fails, note it and continue.

### 3. Plan gate (`--plan` only)

Analyze the issue body and the relevant code, present an implementation plan,
and wait for approval before continuing.

### 4. Implement via subagent

Dispatch the `implementer` agent with `isolation: "worktree"`. The brief must
inline the full issue spec (number, title, body, acceptance criteria) — the
agent has no conversation history. TDD applies where a test harness exists.

When it returns:

- Review the diff yourself as the evaluator (behavior over implementation).
- Verify placement: `git worktree list` + `git branch -v` show the main tree
  untouched and the feature branch at the agent's commits.

### 5. Open the PR (confirmation gate)

Present the diff summary and proposed PR title/body to the user and **wait for
explicit approval before pushing or creating the PR**. The PR body must
contain `Closes #$issue` so the merge auto-closes the issue.

### 6. Watch CI through merge

Delegate the watch to the `pr-monitor` skill's bundled script (shared poller —
state-change emission, full failure coverage, approval-gated checks excluded):

```
Monitor:
  persistent: true
  description: "PR #<pr> — CI + review threads (issue #$issue)"
  command: bash "$HOME/.claude/skills/pr-monitor/scripts/pr-monitor.sh" <pr> <owner> <repo> "require-approval,check-approval" merged
```

This is `/pr-monitor <pr> --until merged --auto-fix` in spirit: the PR was
already approved in step 5, so CI-fix pushes need no further confirmation.

React to events:

- `failures` non-empty → fetch the failing log (`gh run view --log-failed`),
  reproduce on the PR branch, fix, push, keep watching. Max 3 fix attempts
  per check name, then stop and re-plan with the user. Never force-push.
- `DONE: merged` → verify the issue auto-closed; if not:
  `gh issue close $issue --comment "Shipped in <PR URL>"`. Then clean up:
  delete the local branch (`git branch -D` — squash merges are not detected
  by `-d`) and remove the implementer worktree if it remains
  (`git worktree remove <path>`).
- `DONE: closed without merge` → report to the user; do not close the issue.
- `[POLL_ERROR]` repeating → stop the watch (TaskStop) and tell the user to
  check `gh auth status` / network.

## Out of scope (v1)

- Multi-issue parallel shipping (Agent Teams fleet) — future separate skill.
- Drafting ticket text for external trackers — separate concern, human-owned.
