---
name: pr-monitor
description: |
  Watch a GitHub PR asynchronously until CI is green and review threads are
  resolved (or through merge), using the harness Monitor tool so the main
  session keeps working. Optional auto-fix mode reacts to CI failures by
  fixing and pushing on the PR branch.
  Use when (1) the user asks to watch a PR or CI (「PR見てて」「CI監視して」),
  (2) changes were just pushed and CI needs confirmation, (3) another skill
  (e.g. issue-ship) needs CI watched through merge. Self-contained — no
  plugin dependency, so it works on every machine.
argument-hint: "[pr-number] [--until merged] [--auto-fix] [--exclude name1,name2]"
---

# PR Monitor

```
/pr-monitor                       # watch current branch's PR until green
/pr-monitor 123                   # watch PR #123
/pr-monitor 123 --until merged    # keep watching through merge/close
/pr-monitor 123 --auto-fix        # fix CI failures on the PR branch as they appear
/pr-monitor 123 --exclude e2e     # exclude additional check names
```

## Steps

### 1. Resolve PR, owner, repo

If no PR number was given, detect the current branch's PR with `gh pr view --json number,url,title`. No PR found → report and stop. Resolve the repo with `gh repo view --json owner,name`.

### 2. Build the exclude list

Start from `require-approval,check-approval` (approval-gated checks only go green when a human clicks Approve — waiting on them is pointless). Append any `--exclude` values. Validate each name: ASCII alphanumerics, hyphens, underscores, dots, slashes, and spaces only — reject anything with shell metacharacters instead of quoting it.

### 3. Launch the Monitor (once)

```
Monitor:
  persistent: true
  description: "PR #<N> — CI + review threads"
  command: bash "${CLAUDE_SKILL_DIR}/scripts/pr-monitor.sh" <PR> <OWNER> <REPO> "<EXCLUDED>" <green|merged>
```

The 5th argument is `merged` when `--until merged` was passed, otherwise omit it (defaults to `green`). Print a one-line confirmation with the PR URL and end the turn — events arrive as notifications; do not poll or block.

## Event format

The script emits one line per state change (silence = nothing changed) and preserves the last known state across transient fetch failures:

```text
CI {"total":7,"pending":3,"failed":0,"failures":[]} | Reviews {"total":4,"unresolved":2} | PR OPEN
CI {"total":7,"pending":0,"failed":1,"failures":["test-unit"]} | Reviews {"total":4,"unresolved":2} | PR OPEN
DONE: all checks green and threads resolved
DONE: merged
DONE: closed without merge
[POLL_ERROR] 3 consecutive fetch failures — check gh auth / network
```

`failed` covers every terminal non-success conclusion (FAILURE, CANCELLED, TIMED_OUT, ACTION_REQUIRED, STALE, ERROR, STARTUP_FAILURE) — silence is never a missed crash.

## Reacting to events

Default mode is watch-and-report: surface failures with check names to the user; decisions (rerun, fix, ignore) are theirs. On `DONE: all checks green`, tell the user the PR is ready.

### Auto-fix mode (`--auto-fix`)

Invoking with `--auto-fix` is the user's standing approval to push follow-up fixes to this PR's branch — and only this branch. On each failure event:

1. Fetch the failing run log (`gh run view --log-failed`) and reproduce locally on the PR branch.
2. Fix, verify locally, push. Keep the Monitor running — the next event confirms the outcome.
3. Hard limits: max 3 fix attempts per check name, then stop and report (oscillation guard). Never force-push. Never change scope beyond making the named checks pass; anything structural goes back to the user.

`[POLL_ERROR]` repeating → stop the Monitor (TaskStop) and tell the user to check `gh auth status` / network. After `DONE: merged` or `DONE: closed`, no further pushes — the approval expires with the PR.
