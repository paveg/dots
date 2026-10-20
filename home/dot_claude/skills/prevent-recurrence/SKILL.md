---
name: prevent-recurrence
description: >-
  Find the mistakes that keep recurring in a repo and make each one impossible to repeat: fix it at the highest level that works (architecture, type, lint/CI, test, hook, rule) and prove every new check fails on a real past occurrence. Use on 「再発防止」「同じミスを防いで」「また同じ間違い」, or when a correction repeats a class already recorded.
argument-hint: "[<mistake class to focus on>]"
disable-model-invocation: true
---

# Prevent Recurrence

Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. The goal is a repo where a change that looks right from one file is right for the whole repo. A rule an agent can skip prevents nothing; prefer changes that make the mistake fail.

## 1. Gather occurrences

Read these sources and list every mistake you find, each with a pointer to where it happened:

| Source                         | What it shows                                                     | How                                                                    |
| ------------------------------ | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| git history                    | reverts, and fixes that repair a recent commit                    | `git log --oneline -200`, `git log --grep='^Revert'`, `git show <sha>` |
| PR review comments             | what reviewers had to point out                                   | `gh api repos/<owner>/<repo>/pulls/comments --paginate`                |
| PR bodies                      | `## Encodable findings` lines left by the review stage            | `gh pr list --state merged --limit 100 --json number,body`             |
| agent memory                   | corrections the user gave about how agents work                   | `feedback`-type files in the project's memory directory                |
| instruction files and comments | workarounds and "do not do X" notes that exist because X happened | CLAUDE.md, rules, comments with `IMPORTANT` / `do not`                 |

## 2. Group into classes

A class is a mistake that happened at least twice. One occurrence is a fix, not a class; leave it out. For each class, cite every occurrence (commit SHA, PR comment URL, memory file). Two occurrences that only look alike are not a class unless the same change would have prevented both.

## 3. Pick the highest level that works

Try each level from the top and stop at the first one that would make the class fail. Write one line for every level above the chosen one saying why it does not work.

1. `architecture`: one owner for each piece of state, one supported way for each task, internals the wrong import cannot reach, one source of truth instead of hand-synced lists. Delete the old way and any dead example an agent would copy.
2. `type`: make the bad state unrepresentable, so the bad code does not compile.
3. `lint`: a lint rule or CI check whose error message names the file, function, or pattern to use instead. If the bad pattern is already common, fail only on additions (compare against the base branch) rather than on every existing instance.
4. `test`: a test that fails when the behavior breaks and keeps passing when only internals change.
5. `hook`: for a mistake in an agent's actions rather than in code, a hook that blocks the action. Use it when the action is irreversible or a rule has already failed to stop it.
6. `rule`: written guidance, only for a judgment no command can decide. A class a command can decide without false positives is never `rule`.

## 4. Build and prove

For each class, one commit:

- Make the change at the chosen level.
- Prove it fails on a real past occurrence: check out the commit where the mistake happened (`git worktree add <tmp> <sha>`, or apply the mistake's diff to a scratch branch), run the new check there, and capture the failing output. Then run it on the current tree and capture the passing output. A check that was never seen failing on a real occurrence proves nothing.
- Run the same command locally that CI will run.
- If an existing instance must stay, mark it on its line with the reason; do not widen the check's exceptions.

## 5. Report

```
| class | occurrences | level | why not higher | change | red on | green on |
```

`red on` and `green on` hold the commit or tree and the command output. After the table, list the single occurrences you left out and why.

Pushing and opening a PR need the user's approval, as for any other change.
