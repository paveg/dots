# 0001. Auto-triggering accumulated Japanese-writing quality at the moments that matter

## Status

Proposed — 2026-07-22

## Context

Over time this repo has accumulated a substantial body of Japanese-writing quality knowledge:

- `dot_claude/rules/japanese-writing.md` — an **always-on** rule (loaded via the global `CLAUDE.md`) that codifies AI-smell avoidance, particle discipline, rhythm/burstiness guidance, and terminology consistency.
- `dot_claude/skills/japanese-ai-writing-proofreader/` — a four-pass proofreading skill (textlint → deterministic rhythm/statistics `lint.py` → AI-smell removal → deep naturalness).
- Generation skills (`technical-writing`, `article-writing`) that lean on the proofreader as their finishing pass.

The problem is **timing, not coverage**. The proofreader fires only on explicit request (「校正して」「自然な日本語にして」). During the moments where readable Japanese matters most — writing a PR description, producing documentation, replying to review comments — none of this machinery engages automatically. The user has to remember to ask.

### Root cause: dilution of passive always-on guidance

The tempting diagnosis — "no rule exists" — is wrong. `japanese-writing.md` is _already_ always-on and still does not reliably change the output. An always-on rule competes with everything else in context; at the moment of writing a PR body, its salience is low and its rhythm/statistics checks (which need deterministic computation, not recall) are effectively never applied.

The design consequence is strict: **the fix must not be "add another passive rule."** That would reproduce the failure. A fix has to be one of:

1. **Just-in-time salience** — inject the relevant guidance _at the moment_ the agent is about to write, so it is unmissable (harness / pre-design).
2. **Deterministic post-hoc check** — run `lint.py` on the produced text and surface findings mechanically, independent of the agent's recall (guardrail / post-verification).

This maps directly onto the repo's own `harness-engineering.md` taxonomy (Harness = pre-design, Guardrail = post-verification) and its directive to "push checks toward guardrails whenever a deterministic tool can do the job."

### Two axes of "natural Japanese": structure vs fingerprint

Prior art (k16shikano's `cognitive-rhythm-writing` method and laiso's commentary "なぜAI臭さを消したいのか") sharpens what "readable Japanese" actually means. There are two independent axes, and they demand different mechanisms:

- **Structural / cognitive readability** — does the prose alternate the reader's cognitive mode (observation → deliberation → certainty → re-examination) and hold unresolved tension? The method's core diagnostic is **状況を更新する文 (updates the situation)** vs **文書を更新する文 (updates only the document — "dead prose": progress announcements, self-description, unsubstantiated disclaimers)**, plus a short-long-short sentence rhythm, dense→ sparse alternation, and no self-reference to rhetorical devices. This property lives **only at generation time** and **cannot be verified by a lint** — it needs the writer to hold the principle while writing.
- **Surface fingerprint** — favored vocabulary, em-dashes, uniform sentence length (the "unslop" axis). This **is** detectable post-hoc; it is exactly what `lint.py`'s rhythm/statistics pass and textlint catch.

The accumulated assets split cleanly along this line: `japanese-writing.md`'s rhythm rules + `lint.py` ≈ the fingerprint axis; `cognitive-rhythm-writing` ≈ the structural axis. The two axes align with the two mechanisms — structural → harness/injection (generation-time salience), fingerprint → guardrail/lint (post-hoc detection).

**Non-goal (from laiso's caution):** the objective is genuine reader comprehension, not removing evidence of AI authorship to satisfy colleagues. Reducing "readability" to "AI-fingerprint removal" would pass the lint while missing the goal. The design therefore treats the **structural (harness) layer as primary** and the fingerprint (lint) layer as a secondary safety net — never lets the mechanical lint become the definition of good Japanese.

### An existing, proven pattern to build on

The repo already ships the exact mechanism needed for option 1: `dot_claude/hooks/executable_gh-pr-inject.sh` is a `PreToolUse(Bash)` hook that injects `gh-pr-body.md` as `additionalContext` whenever it detects `gh pr create|edit`. This is JIT salience for PR formatting, already wired into `settings.json.tmpl`. The Japanese-quality assets are not connected to it.

Every hook in this repo also ships a `tests/hooks/*.test.sh` (`block-destructive-db`, `block-rot-comments`, `browser-inject`, …); any new or extended hook inherits that contract.

### Scope and enforcement decisions (settled with the user)

- **Target moments for v1: documentation (`.md` Write/Edit) and PR descriptions (`gh pr create|edit`).** Review responses are **deferred** — they are short, and `lint.py`'s rhythm/burstiness statistics are noise on one or two sentences. They may return in a later revision as nudge-only.
- **Enforcement is staged, starting non-blocking.** `lint.py` was _deliberately_ authored as `exit 0` ("これは CI ゲートではなく lint"). A blocking gate contradicts that decision, so we do not start there. We begin non-blocking and promote a moment to a gate only after its false-positive rate is shown to be acceptable.

## Decision

Adopt a **hybrid, layered design** that assigns each moment the mechanism it fits, rolled out in three independently-shippable stages. Enforcement strength rises per stage; each stage is gated on evidence from the previous one.

### Moment × mechanism

| Moment                | Mechanism                                      | Why                                                                                                                                                                                                                                                        |
| --------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PR description        | JIT injection nudge (extend `gh-pr-inject.sh`) | Body is inline `--body` vs `--body-file`; a deterministic lint needs extraction, but `additionalContext` injection is trivial and already proven here. `gh pr create` is Bash, so a guardrail must be `PreToolUse` (post-execution the PR already exists). |
| Documentation (`.md`) | Deterministic `lint.py` guardrail              | The file target reliably exists, so `lint.py` runs directly. Strongest guardrail candidate — the "deterministic tool can do the job" case.                                                                                                                 |
| Review responses      | _(deferred)_                                   | Text too short for rhythm statistics; nudge-only or out of scope for v1.                                                                                                                                                                                   |

The table shows each moment's _post-hoc_ (guardrail-layer) mechanism. The Stage 0 _structural_ injection applies to **both** the PR and doc moments — it is the generation-time layer that sits ahead of whatever guardrail (if any) follows.

### Staged rollout

**Stage 0 (v1) — JIT injection nudges. Zero added latency, non-blocking.** Attack the dilution root cause directly with salience at the moment of writing. The injected content carries the **structural** layer (which no later lint can verify): a compact pointer to the canonical norms reference (see Assets below and ADR 0002) — the situation-vs-document test, hold-tension, dense→sparse alternation, no device self-reference — plus a reminder to finish with `japanese-ai-writing-proofreader` (fix mode) for the fingerprint layer.

- **PR:** extend `executable_gh-pr-inject.sh` so its injected `additionalContext`, when the body is Japanese, also carries the structural pointer + proofreader reminder.
- **Docs:** add a `PreToolUse(Write|Edit)` hook that, when `file_path` ends in `.md` and the content contains Japanese, injects the same reminder as `additionalContext`. Guard hard (extension + Japanese-character check) so it stays silent on code and English files. Optional per-session dedup via a marker file if repetition proves annoying.

Stage 0 alone reuses the proven `gh-pr-inject` pattern, adds no `sudachi` startup cost, and directly counters "passive guidance loses salience."

### Assets: the structural layer's home — see ADR 0002

The structural layer needs a durable home that Stage 0 can point at. The original draft of this ADR made it a standalone `cognitive-rhythm-writing` skill; **[ADR 0002](0002-writing-skill-knowledge-consolidation.md) supersedes that**: the structural principles fold into a single canonical norms reference (`dot_claude/references/japanese-writing/`) shared by generation, verification, and this injection layer, rather than becoming a fourth writing skill.

- The `cognitive-rhythm` method is **distilled** in this repo's house style, **credited to k16shikano's source gist** — it is _not_ vendored byte-for-byte. The gist carries no explicit license (GitHub gists default to all-rights-reserved), so unlike the MIT `natural-japanese` vendor precedent (`.../scripts/NOTICE.md`), verbatim copying is not permitted. The method's _ideas_ are not copyrightable; our own expression of them, with attribution, is.
- The reference is loaded **just-in-time**, never folded into the always-on `japanese-writing.md` rule — folding it there would return it to the diluted always-on channel this ADR exists to escape.

Stage 0's injection therefore points at that norms reference plus the proofreader reminder. See ADR 0002 for the full topology.

**Stage 1 — deterministic `lint.py` guardrail. Still non-blocking; adds mechanical verification.**

- **Docs:** run `lint.py` on touched Japanese `.md` files and surface findings. To avoid paying `sudachi`'s ~1–2 s dictionary load on every intermediate edit, the **target architecture is a debounced batch**: a lightweight `PostToolUse(Write|Edit)` step records touched Japanese `.md` paths into a per-session queue, and a `Stop` hook drains the queue once per turn, running `lint.py` a single time over the unique set. (A simpler direct-`PostToolUse` lint is the fallback if the queue mechanism proves heavier than the latency it saves.)
- **PR:** optionally add a `PreToolUse(Bash)` step that extracts `--body` / `--body-file`, runs `lint.py`, and injects findings as `additionalContext` (still the agent's call — non-blocking).

**Stage 2 — promote proven moments to a blocking gate.** Only for a moment whose false-positive rate is acceptable in practice:

- **Docs:** a `Stop` hook that refuses to end the turn while a touched Japanese `.md` still carries un-addressed high-confidence findings.
- **PR:** a `PreToolUse(Bash)` deny on `gh pr create` when the Japanese body has un-addressed high-confidence findings.

The ADR records that Stage 2 is conditional; it is not scheduled by default.

### Gate-promotion criteria (Stage 1 → Stage 2)

Promote a moment from non-blocking to blocking only when all hold:

1. The nudge/lint has run on ≥ ~10 real deliverables at that moment.
2. Observed false-positive rate (findings the user would override) is low enough that blocking would not routinely obstruct correct output.
3. The `lint.py` categories used for the gate are restricted to high-confidence ones (e.g. mechanical textlint / clear rhythm outliers), not subjective naturalness.

Until then the moment stays non-blocking.

## Consequences

### Positive

- Directly addresses the measured failure (dilution) with JIT salience rather than another passive rule.
- Reuses an existing, tested pattern (`gh-pr-inject`) for the PR moment — small, low-risk change.
- Deterministic verification (`lint.py`) is layered in where it is strongest (docs with a real file target) and kept out where it is noise (short review replies).
- Separating the structural axis (harness) from the fingerprint axis (lint) keeps the design honest about the goal: readability the lint cannot see is served by generation-time salience, not faked by passing statistics.
- Each stage ships independently and reversibly; enforcement escalates only on evidence, honoring `lint.py`'s original non-gate intent and the user's "段階導入" choice.

### Negative / costs

- Two mechanisms to maintain (injection hooks + lint guardrail) instead of one.
- Stage 1's `sudachi` dictionary load adds latency; the debounced `Stop`-batch design is the mitigation but is more moving parts than a direct per-edit lint.
- Injection nudges can themselves lose salience if over-fired; the Japanese-character + `.md` guards and optional per-session dedup keep them rare.
- `PreToolUse(Write|Edit)` widens the set of tool calls that run a hook; the guard must fail closed to silence (never block, never error) on non-Japanese files.
- The `cognitive-rhythm-writing` skill is a distillation, not a verbatim vendor (source gist is unlicensed), so it can drift from upstream; attribution plus a note to re-check the source on major upstream changes is the mitigation.

### Done criteria (verifiable)

- **Stage 0:**
  - The canonical norms reference exists (per ADR 0002) and carries the cognitive-rhythm structural principles, credited to the source gist.
  - `gh pr create`/`gh pr edit` with a Japanese body injects a reminder pointing at the norms reference + the proofreader; English bodies do not.
  - A `.md` Write/Edit with Japanese content injects the reminder; a `.py`/`.ts` edit or an English `.md` injects nothing.
  - `tests/hooks/*.test.sh` covers both fire and no-fire paths for the new/extended hook, and `just test` passes.
- **Stage 1:** touched Japanese `.md` produces `lint.py` findings once per turn (not once per edit); running order and non-blocking behavior verified by a hook test.
- **Stage 2 (if pursued):** blocking path denies on high-confidence findings and allows once addressed; verified by a hook test.

### Follow-ups / out of scope

- Review-response coverage (nudge-only) — revisit after Stage 0/1 land.
- Wiring `settings.json.tmpl` entries for the new hooks (implementation detail for the plan, not this decision).
