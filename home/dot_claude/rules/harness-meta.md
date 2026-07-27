---
paths:
  - "**/.claude/**"
  - "**/dot_claude/**"
  - "**/CLAUDE.md"
---

# Harness Meta

Rules for maintaining the harness itself (rules, hooks, skills, agents).

## Rule Hygiene

Long instruction sets degrade model behavior — IFScale (arxiv 2507.11538) shows primacy bias kicks in around 150–200 instructions, and Chroma's context rot study confirms degradation across all 18 frontier models tested. The fix is volume discipline, not "just one more bullet."

- Treat the always-loaded rule set in `~/.claude/rules/` as a budget capped near **150 effective instructions**
- When near the cap, every new rule must come with a **proposed deletion or downgrade** of an existing one (grow-by-replace)
- Project-specific rules (framework, ORM, deployment target) belong in the project's CLAUDE.md, not the global set
- Detail-heavy or rarely-applicable rules should be scoped with `paths:` frontmatter so they load only when matching files are touched
- Periodically audit: which rules have not prevented a real failure in the last few months? Drop them

## Escalation Ladder

Where to place a new constraint, by violation history and reversibility:

| Level | Location                                    | When to use                                                                   |
| :---- | :------------------------------------------ | :---------------------------------------------------------------------------- |
| L1    | Mention in `CLAUDE.md` or task instructions | First occurrence; soft preference                                             |
| L2    | New/extended rule in `~/.claude/rules/*.md` | Same issue noticed twice or more                                              |
| L3    | `~/.claude/hooks/` (PreToolUse, Stop, etc.) | Repeated violation OR irreversible action (push --force, rm -rf, secret leak) |
| L4    | Project CI / required check                 | Production impact, security, or compliance                                    |

- Skip levels when the action is irreversible — go straight to L3+ instead of trusting prose
- Prefer machine-checkable enforcement (L3/L4) over instructions (L1/L2) whenever a deterministic check is possible
- See `harness-engineering.md` for why this matches "the stronger the mechanical verification, the more autonomy"

## Harness Simplification

- Each guardrail encodes an assumption about what the model cannot do reliably
- Periodically question whether a guardrail is still necessary
- Remove ceremony that no longer prevents real failures
- When a model upgrade lands, audit which guardrails were patching the old model's limits and drop the ones that no longer earn their cost

## TDD for Rules and Hooks

Rules and hooks under `~/.claude/` are also code; they deserve the same Red-Green-Refactor discipline before being committed.

1. **Red**: Reproduce the failure pattern _without_ the new rule/hook in place. Confirm the agent fails the way you expect
2. **Green**: Add the rule or hook. Confirm the same scenario is now blocked or corrected
3. **Refactor**: In a fresh session, probe edge cases — paraphrased prompts, adjacent tasks — to confirm the rule is not just memorized to one phrasing

A rule added without a Red step is indistinguishable from cargo culting. If you cannot articulate the concrete failure it prevents, do not add it.
