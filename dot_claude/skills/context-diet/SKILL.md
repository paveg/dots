---
name: context-diet
description: >-
  Measure and cut what skills, rules, and CLAUDE.md cost in agent context, sorted by when the cost is paid. Use when the always-loaded set has grown, after adding several skills, when a model upgrade makes old guardrails redundant, or on 「コンテキストを削りたい」「rules を整理して」「skill が重い」.
argument-hint: Optional target (defaults to ~/.claude skills + rules)
---

# Context Diet

Cutting the wrong thing is the usual failure. A 14,000-character SKILL.md body costs nothing until someone invokes it; a 977-character `description` is paid on every turn of every session forever. Measure before editing.

## Three cost classes

| Class         | What is in it                                                            | Paid                          |
| :------------ | :----------------------------------------------------------------------- | :---------------------------- |
| **always-on** | rules without `paths:`, every skill `description`, CLAUDE.md             | every turn, every session     |
| **on-invoke** | SKILL.md body                                                            | once, when the skill fires    |
| **on-demand** | `references/**`, `scripts/**`, `paths:`-scoped rules, hook-injected rules | only when actually reached    |

Always-on is the only class worth fighting over. Moving text from on-invoke to on-demand is worth doing when a skill has phases that are not all reached in one run — it is not worth doing to a skill that reads top-to-bottom every time.

## Measure

```bash
python3 ~/.claude/skills/context-diet/scripts/measure.py \
  --skills ~/.claude/skills --rules ~/.claude/rules
```

Character counts, not tokens — the ratio is stable enough to rank by, and it stays reproducible across model changes. Add `--format tsv` to diff two runs. Rules with `paths:` land in on-demand; skills flagged `<- no references/` have a large body and nowhere to put it yet.

Two costs the script cannot see, so check them by hand:

- Rules listed in `claudeMdExcludes` (in `settings.json`) never load, whatever their frontmatter says. If a PreToolUse hook injects them instead, they are on-demand, not always-on
- Skills set to `"off"` in `skillOverrides` cost zero. Their size is a maintenance question, not a context one

## Where the budget actually goes

Rules usually dominate skill descriptions by 3:1 or more. Check that ratio first — if it holds, spending an afternoon compressing skill descriptions is optimizing the smaller half.

Within rules, look for a single file carrying most of the weight. A rule that has accumulated planning, delegation, verification, and task-management sections is several rules wearing one hat, and only one of them is relevant on a given turn.

## The four ways to move something out of always-on

Pick by what the trigger is, not by preference:

- **`paths:` frontmatter** — the rule applies to a file type. Loads when a matching file is touched
- **PreToolUse hook injection** — the rule applies to an action. `claudeMdExcludes` drops it from always-on, and the hook re-injects it on the matching tool call. Strictly better than `paths:` when the trigger is a command rather than a file
- **`references/` file** — the content is only reached at a specific step. Leave a pointer at that step, not a table of contents at the top
- **A skill** — the content is a procedure the model should decide to load. Costs a description in exchange

## Verify before deleting

Removal is a behavior change, so it needs the same Red step as adding: in a fresh session, run a task the text was supposed to govern, without the text. If behavior is unchanged, the text was not doing the work you thought — delete it. If behavior degrades, keep it and shrink it instead.

Consult `references/cut-patterns.md` for what to compress and what to leave alone before writing any edit.

Record the totals after each diet so the next run can see drift.

## Don't

- Don't delete a guardrail that guards an irreversible action. Compress the wording; keep the constraint
- Don't move a negative trigger ("never fire proactively on X") out of a `description` — that is the one place it works
- Don't count a `references/` split as a saving if every run reads every reference anyway
