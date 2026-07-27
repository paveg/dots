---
name: context-diet
description: >-
  Cut what skills, rules, and CLAUDE.md cost in agent context without losing behavior — measure by when the cost is paid, name the failure each candidate was preventing, and have someone else verify the cut. Use when the always-loaded set has grown, after adding several skills, when a model upgrade makes old guardrails redundant, or on 「コンテキストを削りたい」「rules を整理して」「skill が重い」.
argument-hint: Optional target (defaults to ~/.claude skills + rules)
---

# Context Diet

**Cost is the target; behavior is the constraint.** A diet that saves 5,000 characters and loses one guardrail is a bad trade, and the loss will surface weeks later as a mistake nobody connects back to this edit.

Two failure modes, in order of frequency:

- **Cutting the wrong class.** A 14,000-character SKILL.md body costs nothing until someone invokes it; a 977-character `description` is paid on every turn forever. Effort spent on the wrong one buys nothing
- **Cutting load-bearing text.** Silent, delayed, and invisible in the numbers — the totals improve either way

Measure before editing, and know what each cut was holding up before removing it.

## Three cost classes

| Class         | What is in it                                                             | Paid                       |
| :------------ | :------------------------------------------------------------------------ | :------------------------- |
| **always-on** | rules without `paths:`, every skill `description`, CLAUDE.md              | every turn, every session  |
| **on-invoke** | SKILL.md body                                                             | once, when the skill fires |
| **on-demand** | `references/**`, `scripts/**`, `paths:`-scoped rules, hook-injected rules | only when actually reached |

Always-on is the only class worth fighting over. Moving text from on-invoke to on-demand helps when a skill has phases that are not all reached in one run — it does nothing for a skill that reads top-to-bottom every time.

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

## Name the failure first

Before touching any line, answer one question about it: **which concrete failure was this preventing?**

- **No answer** — it is cargo cult. `harness-meta.md` already forbids adding a rule whose failure you cannot articulate; the same test applied backwards is the safest deletion signal there is. Cut it
- **An answer** — write it down. That sentence is now a test case, and the constraint has to survive the edit in some form. Compress the wording, move it to a cheaper class, or fold it into a mechanical check — but the behavior stays

Collect these sentences as you go. They are the regression suite for the whole diet, and they cost nothing to produce because you had to reason about each line anyway.

## The four ways to move something out of always-on

Pick by what the trigger is, not by preference:

- **`paths:` frontmatter** — the rule applies to a file type. Loads when a matching file is touched
- **PreToolUse hook injection** — the rule applies to an action. `claudeMdExcludes` drops it from always-on, and the hook re-injects it on the matching tool call. Strictly better than `paths:` when the trigger is a command rather than a file. Deterministic: the harness decides, not the model
- **`references/` file** — the content is only reached at a specific step. Leave a pointer at that step, not a table of contents at the top
- **A skill** — the content is a procedure the model should decide to load. Costs a description in exchange

The last two are model-triggered, and that is where quality leaks. **A reference nobody reads is a deletion that the totals record as a saving.** Before splitting, decide what makes the pointer fire, and prefer the two deterministic mechanisms whenever the trigger can be expressed as a file glob or a tool call.

Two signals that a split went wrong, both from a later run: the step that should have read the reference never opened it, or the executor burned 3–5× the usual `tool_uses` traversing `references/` looking for something the body should have carried inline.

## Verify

The person who made the cut is the wrong judge of it — `harness-engineering.md` calls this generator-evaluator separation, and a diet is exactly the case it exists for, because the cutter already believes the text was redundant.

- **Test behavior, not the diff.** In a fresh session, run the task each named failure describes. A reviewer reading the diff will agree the text looked redundant; that is the same judgment that produced the cut
- **Use a separate evaluator.** A `skeptic` subagent, `empirical-prompt-tuning` for a prompt that earns the full loop, or the user. Reading your own edit and concluding it is fine is not verification
- **Keep batches bisectable.** One commit per coherent group of cuts. When a regression shows up, you need to know which group caused it, and a single 40-file commit gives you nothing to bisect
- **Record the totals per batch**, so the next diet sees drift and so a saving that came from a silent deletion stands out as suspiciously large

Consult `references/cut-patterns.md` for what to compress and what to leave alone before writing any edit.

## When to stop

A diet with no floor is starvation. Stop when every remaining always-on line has a named failure behind it. What is left is not fat — further cutting trades behavior for bytes, which is the trade this skill exists to prevent.

Two more stopping signals: the measured saving of the next candidate is under a few hundred characters (not worth a verification pass), or you find yourself arguing that a guardrail is _probably_ unnecessary. Probably is not a named failure.

## Don't

- Don't delete a guardrail on an irreversible action. Compress the wording; keep the constraint. Better, check whether a hook already enforces it — then the prose only needs the judgment the hook cannot make
- Don't move a negative trigger ("never fire proactively on X") out of a `description`. That is the one place it works
- Don't count a `references/` split as a saving if every run reads every reference anyway
- Don't cut and verify in the same pass. Propose the full set of cuts, then verify, then apply — interleaving them means the later cuts inherit the earlier ones' unverified assumptions
