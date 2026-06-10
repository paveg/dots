---
alwaysApply: true
---

# Workflow

## Planning

- For non-trivial tasks (3+ steps or architectural decisions): **brainstorm → design → plan** in that order
  - Brainstorm: explore user intent, ask one question at a time, propose 2-3 approaches with tradeoffs
  - Design: get incremental approval on each section before proceeding
  - Plan: break into checkable items only after design is agreed upon
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

## Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### Model Tiers

| Role | Model | How |
| :--- | :---- | :-- |
| Planning, design, architecture, evaluation | Main session (fable/opus) | stay in main process |
| Implementation from an approved plan | sonnet | `implementer` agent (`~/.claude/agents/`) |
| Mechanical single-file edits, grunt work | haiku | `implementer` with `model: haiku` override |
| Exploration / research fan-out | Explore agent | read-only; return conclusions, not file dumps |

- The dispatcher never implements what it will evaluate; the implementer never evaluates its own diff
- On subscription plans (incl. Max), `sonnet[1m]` bills usage credits — for >200K-context tasks, split the task or escalate to `opus` (1M included) instead
- Precondition: `CLAUDE_CODE_SUBAGENT_MODEL` must stay unset (it overrides every per-agent model choice)

### Subagent-Driven Development (default for implementation)

- Once a plan exists, dispatch the `implementer` agent with `isolation: "worktree"` — its
  system prompt carries workspace discipline, hard limits, and the reporting protocol, so
  the brief only needs the task spec itself
- Main session stays as the evaluator (see `harness-engineering.md` generator-evaluator separation);
  it reviews diffs directly instead of spawning review subagents
- Brief subagents with task-relevant context inline — they have no conversation history
- After a worktree agent completes, verify placement: `git worktree list` + `git branch -v`
  must show the main tree untouched and the feature branch at the agent's commits; repoint
  with `git branch -f` if not
- **Push and PR creation require explicit user confirmation** — including post-phase follow-ups (docs, cleanup, completion records). Prefer branch-protection enforcement over discipline.

### Worktree Location

- When creating worktrees manually (sequential subagent dispatch in a shared worktree),
  always use **`<project-root>/.claude/worktrees/<branch-name>`**
- NOT `~/.claude/worktrees/` (user-global) and NOT sibling-of-repo paths (`../foo-branch`)
- Add `.claude/worktrees/` to the project's `.gitignore` if not already excluded
- Rationale: keeps worktrees scoped to the project, avoids cross-project name collisions,
  and makes cleanup obvious (delete with the project, not orphaned in a global cache)
- The Agent tool's `isolation: "worktree"` parameter handles its own worktree placement
  automatically — this rule applies to manually-created worktrees only

### Stay in main process for

- Brainstorming, spec clarification, architecture decisions
- Exploratory work (debugging, bug reproduction, interactive TDD)
- Trivial edits: single file, <10 lines, obvious intent

## Verification

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness
- The verification command must run **in the same message** as the completion claim
- Show the full output and exit code — do not summarize or paraphrase
- Forbidden phrases: "should pass", "probably works", "looks correct", "seems fine"
- Only evidence counts: if you didn't run it, you don't know

## Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes
- Challenge your own work before presenting it

## Systematic Bug Fixing

When given a bug report: fix it without hand-holding, but **investigate before patching**.

1. **Investigate**: Read the error message, reproduce the bug, check recent changes, trace the data flow
2. **Compare**: Find a working case and diff it against the broken one
3. **Hypothesize**: Form a theory, test it with the smallest possible experiment
4. **Fix**: Write a failing test that captures the bug, then fix it, then verify

- After 3 failed fix attempts on the same issue, **stop and re-plan** — do not try fix #4
- Zero context switching required from the user throughout this process

## Task Management

- Track multi-step work with the harness Task tools or plan-document checkboxes; check in before starting implementation
- After any correction from the user, capture the pattern in persistent memory so it survives the session

## Rule Hygiene

Long instruction sets degrade model behavior — IFScale (arxiv 2507.11538) shows primacy bias kicks in around 150–200 instructions, and Chroma's context rot study confirms degradation across all 18 frontier models tested. The fix is volume discipline, not "just one more bullet."

- Treat the always-loaded rule set in `~/.claude/rules/` as a budget capped near **150 effective instructions**
- When near the cap, every new rule must come with a **proposed deletion or downgrade** of an existing one (grow-by-replace)
- Project-specific rules (framework, ORM, deployment target) belong in the project's CLAUDE.md, not the global set
- Detail-heavy or rarely-applicable rules should be `alwaysApply: false` so they load on demand
- Periodically audit: which rules have not prevented a real failure in the last few months? Drop them

## Escalation Ladder

Where to place a new constraint, by violation history and reversibility:

| Level | Location | When to use |
| :---- | :------- | :---------- |
| L1 | Mention in `CLAUDE.md` or task instructions | First occurrence; soft preference |
| L2 | New/extended rule in `~/.claude/rules/*.md` | Same issue noticed twice or more |
| L3 | `~/.claude/hooks/` (PreToolUse, Stop, etc.) | Repeated violation OR irreversible action (push --force, rm -rf, secret leak) |
| L4 | Project CI / required check | Production impact, security, or compliance |

- Skip levels when the action is irreversible — go straight to L3+ instead of trusting prose
- Prefer machine-checkable enforcement (L3/L4) over instructions (L1/L2) whenever a deterministic check is possible
- See `harness-engineering.md` for why this matches "the stronger the mechanical verification, the more autonomy"
