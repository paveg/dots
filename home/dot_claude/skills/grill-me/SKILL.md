---
name: grill-me
description: >
  Relentless round-based interview that sharpens a plan, decision, or idea until user and agent share one understanding, then writes the settled result down — technical trade-offs as ADRs, everything else as a design doc in the repo's convention. Use on 「グリルして」「詰めて」「壁打ちして」「仕様を固めたい」「設計を詰めたい」 or "grill me". Not for executing a plan that already exists.

disable-model-invocation: true
---

# Grill Me

Interview the user relentlessly until you reach a shared understanding, then write that understanding down. Two phases, strictly in order: **interview** (nothing is written), then **write-down** (only after the user confirms). Never implement anything in this skill.

Start from whatever the user has — a loose idea is enough; producing the sharp version is what the session is for. Do not build a plan and ask the user to nod at it.

## Phase 1 — Interview

Map the subject as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round. Independent questions all belong in the current round, even if some feel like details — the frontier is defined by dependencies, not by importance.

Format every question like this:

```
❓ **Q1** - **<question title>**: <question body — may be several paragraphs, may list options>

➡️ <your recommended answer, with a one-clause reason>
```

Each round of answers reshapes the tree — settled decisions push the frontier outward and unblock what depended on them. Recompute the frontier and ask the next round. Count rounds, not questions: many questions in few rounds is the intended shape.

### Facts are yours, decisions are the user's

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, git history, existing docs, tools), dispatch a read-only sub-agent (Explore) or look it up yourself — never ask the user for something you could find. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now.

The _decisions_ are the user's — put each one to them and wait. Answering your own decision questions breaks the skill; it is not a liberal interpretation of it. "I don't know" is a real answer: record it as open.

### Steering

- If the user asks for one question at a time, switch to that pacing for the rest of the session.
- Some questions are **ungrillable** — how something should look or feel, which of two layouts reads better. Talking cannot settle them. Say so, park the question as "needs a prototype", and move on rather than rephrasing it round after round.
- If the frontier keeps growing instead of shrinking, the scope is too large. Say so and propose splitting the subject before continuing.

### Done gate

The interview is done when the frontier is empty — every branch visited, nothing left silently assumed. Then present a compact summary of every settled decision and open item, and ask the user to confirm the understanding is shared. Do not write files or act until they confirm.

## Phase 2 — Write-down

Only after confirmation. Route what was settled to durable files; the conversation is not a durable place.

### What goes where

| What resolved                                                                                                                        | Where it lands                 |
| ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| A technical decision that is **hard to reverse**, **surprising without context**, and **the result of a real trade-off** (all three) | One ADR per decision           |
| Everything else that was settled — scope, behaviour, non-technical decisions, rejected options, open/ungrillable items               | One design doc for the session |
| Nothing settled beyond restating the obvious                                                                                         | Say so and write nothing       |

Most decisions fail the three-gate test; a session that yields one design doc and zero ADRs is normal.

### ADR

- Directory: the repo's existing ADR directory (`docs/adr/`, `docs/decisions/`, `adr/`, or wherever existing ADRs already live). If none exists, create `docs/adr/`.
- Numbering: highest existing `NNNN` + 1; filename `NNNN-short-description.md`.
- Format and language: follow `~/.claude/rules/harness-engineering.md` — English, sections Status / Context / Decision / Consequences. Read the existing ADRs first and match their house style; cite prior ADRs the decision builds on or supersedes.

### Design doc

- Directory: follow the repo's existing convention — look for `docs/superpowers/specs/`, `docs/specs/`, `docs/design/`, `docs/rfcs/`, `design/`, in that order of preference, and match the naming pattern of the files already there. If none exists, create `docs/design/` and name the file `YYYY-MM-DD-<topic>.md`.
- Outside a git repo, there is no convention to follow — ask the user for a path.
- Language: match the neighbouring docs; if there are none, use the language the user ran the session in. Prose is unwrapped (one paragraph per line).
- Template:

```markdown
# <Topic>

## Context

<what was grilled and why, 1–3 sentences>

## Decisions

<numbered; one entry per settled question: what was decided, why, and which alternatives were rejected. Precise answers stay precise — numeric defaults, ordering guarantees, negative requirements are copied verbatim, not softened into prose.>

## Open questions

<unresolved answers ("I don't know") and ungrillable items marked "needs prototype">

## Out of scope

<what the user explicitly excluded>

## Related decisions

<links to the ADRs written this session, if any>
```

### Confirm targets before writing

The output paths are themselves decisions. As the final round, show the exact list of files you intend to create (path + one-line purpose) and wait for approval. Then write them, and print the paths.

## Stop here

Do not implement, plan the implementation, or open a PR. Point the user at the next step in one line (e.g. write a plan from the design doc) and stop.
