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

### Subagent-Driven Development (default for implementation)

- Default execution model once a plan exists: dispatch implementation
  via the Agent tool with `isolation: "worktree"`. The harness creates
  a temporary git worktree, runs the subagent there, and returns the
  worktree path + branch. Auto-cleanup if the subagent made no changes
- Main process stays as the evaluator — satisfies the
  generator-evaluator separation in `harness-engineering.md`
- Briefing must include the relevant rules inline (tdd.md, react.md,
  development-principles.md, etc.) — subagents have no conversation history
- After implementation, dispatch separate review subagents (read-only,
  pointed at the returned worktree path): spec compliance first, then
  code quality
- Subagent may commit inside its worktree; **push and PR creation
  require explicit user confirmation**
- `isolation: "worktree"` works identically in private and business
  environments — it is a core harness feature, not a plugin
- If `superpowers:subagent-driven-development` is available, it layers
  ready-made implementer / spec-reviewer / code-quality-reviewer prompts
  on top. Otherwise dispatch manually — the policy is the same

### Stay in main process for

- Brainstorming, spec clarification, architecture decisions
- Exploratory work where the next step depends on what you just saw
  (debugging, bug reproduction, interactive TDD without a plan)
- Trivial edits: single file, <10 lines, obvious intent
- Work where mid-execution human intervention is likely (UI polish,
  taste-sensitive content)

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

## Self-Improvement Loop

- After ANY correction from the user: update tasks/lessons.md with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

## Task Management

- **Plan First**: Write plan to tasks/todo.md with checkable items
- **Verify Plan**: Check in before starting implementation
- **Track Progress**: Mark items complete as you go
- **Explain Changes**: High-level summary at each step
- **Document Results**: Add review section to tasks/todo.md
- **Capture Lessons**: Update tasks/lessons.md after corrections
