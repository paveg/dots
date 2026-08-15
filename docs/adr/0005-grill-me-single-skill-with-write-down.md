# 0005. grill-me: single inline skill with a post-confirmation write-down phase

## Status

Accepted — 2026-08-15.

## Context

The user wanted a `grill-me` equivalent of [mattpocock/skills](https://github.com/mattpocock/skills) in this repo, extended so that what a session settles is written to disk — technical decisions as ADRs, everything else to a recommended directory (`docs/adr` etc.).

The reference is a three-skill family: `grilling` (the round-based interview primitive, model-invocable), `grill-me` (a one-line user-invoked front door: "Run a `/grilling` session", stateless, writes nothing), and `grill-with-docs` (the same front door plus `domain-modeling`, which writes `CONTEXT.md` glossary terms inline during the session and offers ADRs behind a three-gate test). Its own docs list two recurring failures: a wrapper skill that names another skill does not reliably cause it to load, producing an improvised question dump; and "where did all my other decisions go?" — the glossary is not a spec, most answers fail the ADR gate, and the rest lives only in the conversation.

Repo constraints: skills are English (`CLAUDE.md`), ADRs follow `~/.claude/rules/harness-engineering.md` (English, `NNNN-short-description.md`, Status / Context / Decision / Consequences), design docs already have a home under `docs/superpowers/specs/`, and `~/.agents/skills` symlinks to `~/.claude/skills` so Codex reads the same skill (hence `agents/openai.yaml` stays).

## Decision

Ship **one** skill, `home/dot_claude/skills/grill-me/SKILL.md`, user-invoked only (`disable-model-invocation: true`), with two strictly ordered phases:

- **Interview** — the reference `grilling` mechanics inlined verbatim in spirit: design tree, frontier, rounds, `❓ Qn` + `➡️ recommendation` format, facts looked up by the agent (Explore sub-agent) vs decisions put to the user, opt-in one-question-at-a-time pacing, ungrillable items parked as "needs prototype", and a confirmation gate before anything is written.
- **Write-down** — after confirmation only. Decisions passing the three-gate test (hard to reverse, surprising without context, real trade-off) become one ADR each in the repo's existing ADR directory (`docs/adr/` if none). Everything else settled — scope, behaviour, rejected options, open and ungrillable items — becomes one design doc per session in the repo's existing spec/design directory (`docs/superpowers/specs/`, `docs/specs/`, `docs/design/`, `docs/rfcs/`, `design/`; `docs/design/YYYY-MM-DD-<topic>.md` if none; ask outside a repo). Target paths are shown and approved as the final round before writing.

### Rejected alternatives

- **Primitive + front door split (`grilling` / `grill-me` / `grill-with-docs`)**: mirrors the reference but reintroduces its "wrapper never loaded the primitive" failure, and nothing else in this repo would consume the primitive. If a second consumer appears, extract the interview section then.
- **Inline writing during the interview (`CONTEXT.md` glossary as in `grill-with-docs`)**: an abandoned session leaves half-written files, and this repo has no glossary practice to feed. Writing once after confirmation matches the repo's existing show-the-shape-before-committing habit.
- **Stateless (`grill-me` verbatim)**: the user's explicit requirement was that the settled result lands on disk.

## Consequences

### Positive

- One file to read; no cross-skill loading dependency, so the interview format is followed or the failure is obvious.
- Precise answers survive the session: the design doc template says to copy numeric defaults, ordering guarantees, and negative requirements verbatim instead of softening them into prose.
- ADR output already conforms to the house format and numbering, so a session's ADR slots straight into `docs/adr/`.

### Negative / accepted trade-offs

- The interview cannot be reused by another skill without either duplicating text or extracting a primitive later. Accepted: no consumer today.
- Directory detection is a fixed preference list; a repo with an unusual layout must tell the skill where to write (the final "confirm targets" round is the escape hatch).
- The default round-based pacing differs from `~/.claude/rules/workflow.md`'s "one question at a time" brainstorm style. Accepted: rounds are the point of grilling; the skill switches on request.

### Verification

- `just test` green with the new skill present (format check covers the SKILL.md).
- An independent sub-agent executed the skill on a sample topic and produced a numbered round in the specified format without answering its own decision questions or writing files.
