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

- Once a plan exists, dispatch implementation via `Agent` with `isolation: "worktree"`
- Main process stays as the evaluator (see `harness-engineering.md` generator-evaluator separation)
- Brief subagents with relevant rules inline — they have no conversation history
- After implementation, dispatch separate review subagents: spec compliance, then code quality
- **Push and PR creation require explicit user confirmation**

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
