---
name: adversarial-review
description: >-
  Break a change before it ships: extract the claims a diff, PR body, or
  subagent report makes, add the ones an attacker would test that nobody
  wrote down, run each through its decisive check, and return a verdict
  table ending in PASS or FAIL. Use on
  「敵対的レビューして」「反証して」"adversarial review", and as issue-ship's
  gate before PR creation.
argument-hint: "[<diff ref> | <PR number> | <md paths>] (defaults to git diff main)"
---

# Adversarial Review

A change ships with a story about itself: what it fixes, what it leaves untouched, what its tests cover, how many things it removed. The story is written by whoever made the change, and it reads the same whether or not it is true. This skill takes the story apart into claims, adds the claims the story left out, and tries to break each one, so the verdict rests on what ran, not on what was said.

Existing pieces do the checking; this skill only extracts, routes, and adjudicates. It creates no agents of its own.

## Inputs

- Default target: `git diff main` (or the ref given). Claims come from the diff itself (comments, test names), the commit messages on the branch, the PR body draft, and any subagent final report in the current context.
- Given md paths or a PR number: use those as the source of claims instead.

## Procedure

### 1. Enumerate the claims

Build `| claim | source | kind |`. One row per claim; split compound sentences, because the second half is where the unchecked part hides. `kind` is one of:

| kind     | what it asserts                                                     | example                                   |
| -------- | ------------------------------------------------------------------- | ----------------------------------------- |
| behavior | something now works, no longer happens, or was left unchanged       | "fixes the timeout", "no behavior change" |
| doc      | a factual statement in an md file touched by the change             | "the API defaults to 30s"                 |
| test     | a behavior is protected by tests                                    | "covered by the new unit test"            |
| count    | a number of things were removed, merged, migrated, or accounted for | "deleted the 7 unused rules"              |

Rank by blast radius — what is wrong downstream if this claim is false — and keep the load-bearing rows. "Tests pass", "backward compatible", "nothing else changed", and every number are load-bearing by default.

### 1b. Derive the claims nobody wrote down

The stated claims were chosen by the author, so the author's blind spots never appear in them. Switch stance: you are trying to break this change, and you get to pick where. For each angle below, ask "what would I do to make this fail?", then write the answer as a claim the change is implicitly making, with `source: implicit`, and give it a `kind` so it rides the same routing:

| angle           | the implicit claim                                                                                         |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| trust boundary  | inputs crossing it (user data, env, external responses) are validated; malformed or empty ones are handled |
| error paths     | a failure, retry, or partial completion leaves no lost data and no half-applied state                      |
| ordering        | the result does not depend on call order, timing, or concurrent runs                                       |
| touched callers | every caller of a changed or removed function was updated — "nothing else changed" made concrete           |
| removal         | what was deleted or replaced is gone everywhere, and what replaced it covers every prior use               |

Bound it: the six-skeptic cap in step 2 covers stated and implicit rows together, so an implicit claim earns a slot only when its blast radius beats a stated one. Security attack surface (injection, authz, secrets) belongs to `pentest-parallel-prs`; hand it there rather than folding it in here.

A hypothetical is not a finding. Every implicit claim still has to reach a verdict through step 2 — an "it could break if…" that never ran is a row with no evidence, and it does not count against the change.

### 2. Route each claim to its check

- **doc** → invoke the `verify-doc-claims` skill on the touched md paths and take its table as these rows' verdicts. Do not re-derive it.
- **behavior** → dispatch one `skeptic` agent per claim, in parallel, at most 6; when there are more, the blast-radius ranking decides which six. Each brief carries the claim verbatim, the files it concerns, a hint at the decisive experiment (the command that would contradict it), and the instruction to look first for the smallest input or state that makes the claim false — an attacker's opening move, not a reader's. The skeptic is read-only; it cannot run a check that mutates state.
- **test** → break one condition of the subject at a time and confirm the suite goes red. This mutates, so do it in a throwaway worktree (`git worktree add` on the branch, never the working tree), restore after each mutation, and remove the worktree when done. A suite that stays green with the condition broken refutes the claim, whatever the coverage report says.
- **count** → enumerate before and after (`git show main:<path>` against the branch) and account for every item by name. A summary that adds up is not evidence; the list is.

### 3. Adjudicate

Subagent verdicts are hypotheses. Before accepting a REFUTED, open the evidence the skeptic cited (the file:line, the command output) and confirm it says what the verdict says. Before accepting a CONFIRMED on a load-bearing claim, check that the decisive test the skeptic names actually exercises the claim rather than a neighbor of it.

UNVERIFIABLE is allowed only with a stated reason (the check would need mutation the skeptic cannot do, the primary source is unreachable). An UNVERIFIABLE without a reason is an unfinished row.

### 4. Report

```
| claim | kind | verdict | evidence | decisive test |
```

then one line: `ADVERSARIAL: PASS` or `ADVERSARIAL: FAIL (<n> refuted, <m> unverifiable)`.

PASS requires zero REFUTED rows and a reason on every UNVERIFIABLE row. Anything else is FAIL, and the refuted rows go back to whoever made the change — with the evidence, so the fix targets the claim that broke rather than the wording of it.

## Discipline

- The reviewer of a claim never generated it. When this skill runs on the main session's own change, the skeptics and the mutation runs are the evaluators; reading the diff and agreeing with yourself is not a check.
- Never fabricate evidence to close a row. An empty evidence cell with 未確認 is a correct output.
- A green suite proves nothing about the suite. Only a red run on a deliberately broken subject counts for a `test` row.
- Refuting the stated reason while the conclusion stays true is still a refutation; report it as such, with what is actually true.
