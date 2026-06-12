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
| Planning, design, architecture, evaluation | Main session (opus; fable for the hardest) | stay in main process |
| Mid-task escalation at decision points | advisor (fable) | `/advisor fable` — the advisor reads the live transcript and returns guidance |
| Implementation from an approved plan | sonnet | `implementer` agent (`~/.claude/agents/`) |
| Mechanical single-file edits, grunt work | haiku | `implementer` with `model: haiku` override |
| First-pass diff screening (spec compliance) | sonnet | `spec-reviewer` agent (read-only); main session adjudicates its findings |
| Adversarial claim verification | sonnet | `skeptic` agent (read-only); refutes audit findings / hypotheses before acting on them |
| Exploration / research fan-out | Explore agent | read-only; return conclusions, not file dumps |

- The dispatcher never implements what it will evaluate; the implementer never evaluates its own diff
- On subscription plans (incl. Max), `sonnet[1m]` bills usage credits — for >200K-context tasks, split the task or escalate to `opus` (1M included) instead
- Precondition: `CLAUDE_CODE_SUBAGENT_MODEL` must stay unset (it overrides every per-agent model choice)
- The advisor escalates up (approach choice, recurring errors, pre-completion checks) while
  subagent tiers delegate down — they compose; an opus main with a fable advisor is a valid pair
- The advisor runs without tools and only reads the transcript: useful for plans and risk
  checks, but it does NOT satisfy generator-evaluator separation (the evaluator must test behavior)
- Constraints: a fable main session accepts only `fable` as advisor; through a business LLM
  gateway the advisor tool is not guaranteed to work

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

- Never mark a task complete without proving it works: the verification command runs
  **in the same message** as the completion claim, with full output and exit code shown
- Diff behavior between main and your changes when relevant
- If you didn't run it, you don't know

## Demand Elegance (Balanced)

- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Elegance means simpler, not bigger — no refactors, abstractions, or features beyond
  what the task requires

## Systematic Bug Fixing

- Investigate before patching: reproduce the bug, then diff a working case against the broken one
- Capture the bug in a failing test before fixing it (fix-loop limits: see `harness-engineering.md` Oscillation Guard)

## Task Management

- Track multi-step work with the harness Task tools or plan-document checkboxes; check in before starting implementation
- After any correction from the user, capture the pattern in persistent memory so it survives the session
