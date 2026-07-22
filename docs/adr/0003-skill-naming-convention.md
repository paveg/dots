# 0003. Skill naming convention

## Status

Proposed — 2026-07-22.

## Context

The user asked whether skill names can be unified. Skills are invoked by name and
their `name` + `description` load into every session's skill list, so a name is
both an API surface and always-on context. Renaming one is a **hard, breaking
cutover** — Claude Code skills have no alias/redirect, so every invocation habit,
cross-skill pointer, memory entry, and `CLAUDE.md` mention must move at once.

Surveying the current `dot_claude/skills/` set (20 skills) against a
`<subject>-<role/action>` reading shows the heterogeneity is **narrower than it
looks**:

- **Already subject-first and fine** (majority): `browser-e2e-test`,
  `claude-md-layout`, `codex-subagent`, `learning-primer`, `loop-design`,
  `pentest-parallel-prs`, `pr-monitor`, `trend-arbitrage`, `ui-design-standards`,
  `x-post-craft`, `zero-cost-scaling`, `ios-submission-review`.
- **Families that don't cluster** — members share a *suffix*, which sorts them
  apart in an alphabetical list instead of grouping them:
  - writing: `article-writing`, `technical-writing` (+ the verbose outlier
    `japanese-ai-writing-proofreader`).
  - decision: `equity-decision`, `ipo-decision`.
- **Vague single words**: `feature`, `interrupt` — no subject/role, meaning not
  guessable from the name.
- **Method-qualifier-first**: `empirical-prompt-tuning` (adjective leads the
  subject).

So most names already follow an implicit convention; the real defects are family
clustering and a few outliers — not a case for a 20-skill big-bang rename.

## Decision

**Convention (proposed):**

- kebab-case, **subject-first**: `<subject>-<role|action>`. The subject a reader
  would search for leads; the role/action follows.
- A **family of ≥2 skills sharing a subject uses a shared leading stem** so the
  family clusters in the sorted skill list: `writing-*`, `decision-*`.
- Keep one consistent action form within a family (bare stem or gerund, not both).
- Names stay guessable: avoid bare single words that don't say what the skill
  does.

**Migration strategy — recommend lazy, with a big-bang alternative.** Two paths:

- **Lazy (recommended):** apply the convention to all *new* skills now, and rename
  an existing skill only when it is next substantively touched, sweeping every
  cross-reference (pointers, memory, `CLAUDE.md`) in the same change. Spreads the
  breaking cost over normal edits; never renames a skill nobody is touching.
- **Big-bang (alternative):** one PR renames the whole map at once — maximum
  consistency immediately, maximum breakage surface and review risk in a single
  change. Choose this only if the half-migrated state (two forms coexisting) is
  itself unacceptable.

Either way, this ADR **keeps naming independent of ADR 0002** — 0002 deliberately
renames nothing, so the consolidation and the rename stay separately reviewable.

**Concrete rename map:**

| Current | Proposed | Notes |
|---|---|---|
| `technical-writing` | `writing-technical` | family clustering |
| `article-writing` | `writing-article` | family clustering |
| `japanese-ai-writing-proofreader` | `writing-proofreader` | Japanese-ness now lives in the norms reference (ADR 0002), so it drops from the name |
| `equity-decision` | `decision-equity` | family clustering |
| `ipo-decision` | `decision-ipo` | family clustering |
| `feature` | `feature-workflow` (or leave) | optional; low value |
| `interrupt` | leave | single-purpose utility; renaming buys little |
| `empirical-prompt-tuning` | `prompt-tuning` (method as description, not name) | optional |

Under lazy migration the writing family is the natural first cohort — but as its
own follow-up *after* ADR 0002 lands, not bundled into it. Everything not in the
table keeps its current name; it already conforms.

## Consequences

### Positive

- The convention codifies what most skills already do, so adoption is cheap and
  the rule reads as descriptive, not disruptive.
- Families cluster in the skill list, making the repo's skill map scannable.
- Lazy migration spreads the breaking cost over normal edits instead of one risky
  cutover, and never renames a skill nobody is touching.

### Negative / costs

- Two naming forms coexist during migration (old names until each skill is next
  touched); the convention doc must note this is expected, not drift.
- Each rename is a hard cutover with no alias — a missed cross-reference silently
  breaks invocation. A rename checklist (sweep pointers + memory + `CLAUDE.md` +
  `just test`) is mandatory per rename.
- Some renames (`feature`, `empirical-prompt-tuning`) are marginal; the ADR marks
  them optional rather than forcing churn for symmetry's sake.

### Done criteria

- The convention is recorded (a short `dot_claude/rules/` note or a section the
  skills reference) so new skills follow it without re-deriving.
- The rename map is the agreed target; each row executes only when its trigger
  fires, with cross-references swept and `just test` green.

### Follow-ups / out of scope

- Executing any rename — a separate change per the chosen migration strategy,
  after ADR 0002 lands.
