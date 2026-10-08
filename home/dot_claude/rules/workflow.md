# Workflow

## Planning

- Non-trivial tasks (3+ steps or an architectural decision): **brainstorm → design → plan**, in that order. Brainstorm asks one question at a time and offers 2-3 approaches with tradeoffs; design gets each section approved before the next; plan breaks the agreed design into checkable items
- If something goes sideways, stop and re-plan before continuing
- After any correction from the user, capture the pattern in persistent memory so it survives the session

## Delegation

Delegation is decided here and nowhere else. The harness default of not spawning agents unasked wins; this section says how to delegate once it is warranted.

- Spawning has a fixed cost before any work happens: the subagent re-reads the rules, CLAUDE.md, git status, every tool schema it is given (MCP servers included), and the target files the caller already has. A `general-purpose` agent answering one line has measured well over 100K tokens; an agent with a narrow `tools:` list (skeptic, claude-code-guide) costs a fraction of that, so prefer the narrowest agent type that fits. Delegate when the work dwarfs that cost, needs isolation from the caller's context, or when the generator must not be the evaluator. Stay inline for small, high-frequency tasks; on a 1M-context session, context hygiene alone does not justify a spawn
- Codex (`codex-subagent`) is for when an independent model's read is the point — cross-model review, a second opinion on a diagnosis — or when the user asks for it by name. It is not the default owner of coding work
- Roles: the main session plans, designs, and evaluates. `implementer` (sonnet; override `model: haiku` for mechanical single-file edits) implements from an approved plan. `spec-reviewer` (sonnet) screens diffs and `skeptic` (fable: the strongest evaluator, low output volume) refutes claims, both read-only; the main session adjudicates their findings. Explore agents return conclusions, not file dumps
- The advisor (`advisorModel` in settings) — the harness prompt carries its timing; the user wants it used generously beyond that. Also call it for design, architecture, and risk questions: if the reply would be analysis or a recommendation with no file edits, consult first, after any reads (simple factual lookups excepted). It has no tools and reads only the transcript, so it never satisfies generator-evaluator separation
- `sonnet[1m]` bills usage credits on subscription plans: for >200K-context tasks, split the task or use `opus`. `CLAUDE_CODE_SUBAGENT_MODEL` must stay unset or it overrides every per-agent model choice
- Stay in the main process for brainstorming, spec clarification, architecture decisions, exploratory debugging, and trivial edits (single file, <10 lines, obvious intent)

### Subagent-driven implementation

- Dispatch `implementer` with `isolation: "worktree"` and the task spec inline. It has no conversation history; its system prompt already carries workspace discipline and the reporting protocol
- The dispatcher never implements what it will evaluate; the implementer never evaluates its own diff. The main session reviews the diff itself instead of spawning review subagents
- Before dispatching into an existing worktree, its `git status --short` must be empty and HEAD on the intended branch; otherwise create a fresh one. After a worktree agent finishes, `git worktree list` and `git branch -v` must show the main tree untouched and the feature branch at the agent's commits; repoint with `git branch -f` if not
- **Push and PR creation require explicit user confirmation**, including post-phase follow-ups (docs, cleanup, completion records)
- Manually created worktrees go in `<project-root>/.claude/worktrees/<branch-name>` (add it to `.gitignore`), never `~/.claude/worktrees/` or a sibling of the repo: project-scoped, no cross-project name collisions, cleanup obvious. The Agent tool's `isolation: "worktree"` places its own

## Verification

- Never claim a fact without proof. This covers completion claims and any statement of fact in a PR body, commit, report, or file you produce: place the command and its output next to the claim, and state what the output shows, not what you inferred from it ("exists" is a claim about a listing; "is the cluster name" is a claim about what the listing means, and needs its own source). Diff behavior against main when relevant
- A detector needs a positive completion signal: an exit code plus the runner's own summary line. Zero failure matches without that signal is inconclusive, not a pass. A collection or import error is a completed run that says "no test executed"; report it as such, not as a failure or a pass
- Investigate before patching: reproduce the bug, then diff a working case against the broken one
