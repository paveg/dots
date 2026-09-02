# 0008. Distill ponytail into development-principles, excluding its perishable parts

## Status

Accepted — 2026-09-02.

## Context

AI-generated code kept accumulating two kinds of rot: speculative structure (wrappers, one-implementation abstractions, scaffolding "for later") and comments that restate facts owned elsewhere (test counts, caller lists, versions). The existing Simplicity section stated virtues ("avoid over-engineering", "find root causes") without an operational procedure.

[ponytail](https://github.com/dietrichgebert/ponytail) encodes the same goal as a decision ladder. Its git history separates the durable core from the accretions:

- The first commit (2026-06-12) was a 20-line AGENTS.md: the ladder, the prohibitions, the "never simplify away" list.
- Commit dedc97c (2026-06-22, issues #245/#217) added "read the code first", "reuse what is already in the codebase", and "fix the shared function once". Its message records that abstract prose ("trace the flow") did not change model behavior on their benchmark, while the actionable form ("grep every caller") did.
- Everything else — the platform-native lookup tables, lite/full/ultra modes, the `ponytail:` brand marker, benchmark figures, hardware-calibration prose — is plugin mechanics or point-in-time data.

Transcript mining across this machine's Claude Code sessions found no count claims inside code comments; the "N tests" phrasing lives in PR bodies, worklogs, and quoted test output. The user chose a context-light rule over a new hook pattern for this.

## Decision

- Replace the Simplicity section of `home/dot_claude/rules/development-principles.md` with the seven-rung ladder plus its guard rules, phrased as actions (read first, grep callers, reuse, name the ceiling), not virtues.
- Add one Comments rule that subsumes the individual rot categories: a comment must not state a fact whose source of truth lives elsewhere. Living docs follow the same rule; point-in-time records (PR bodies, commit messages, worklogs) are exempt.
- Deliberately exclude ponytail's platform-native tables. Concrete API mappings (`Object.groupBy`, `-webkit-line-clamp`, Python version notes) age within a year; the rule instead says "check current platform docs before reaching for a package".
- Exclude intensity modes, the brand marker, benchmark numbers, and the hardware paragraph. Keep the substance of the marker (name the ceiling and the upgrade condition) as an ordinary why-comment.
- Do not extend `block-rot-comments.py`. The user asked for an aspirational rule, not a guardrail, and the evidence does not show the pattern in code comments.

## Consequences

- No new rule file, no new hook. The Modern Practices section (three abstract virtues with no action) is removed in the same change, following harness-meta's grow-by-replace rule; the always-loaded set still sits above its 150-instruction guideline.
- Future sessions should not re-import ponytail's tables or modes; this record is the reason.
- If count claims start appearing in code comments, the hook is the next step and its test harness already exists (`tests/hooks/block-rot-comments.test.sh`).
