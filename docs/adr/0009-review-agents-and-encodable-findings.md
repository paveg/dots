# 0009. Split review into narrow agents that tag findings as encodable, and fetch yomiyasu as a pinned chezmoi external

## Status

Accepted — 2026-10-20.

## Context

The user wanted the strengths of [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack) folded into the review stage, with an eye to a software-factory pipeline: anything a machine can decide should eventually be decided by one. Most of pstack already had a counterpart here (`adversarial-review` and `skeptic` for `interrogate`, the Simplicity ladder for its core principles). The gaps were a code-quality lens, Comment Sicko's treatment of comments and suppressions, blast-radius's evidence grading, and `correct`'s idea that a recurring mistake should be fixed at the highest enforceable level.

`block-rot-comments.py` already rejects pattern-decidable comment rot at write and commit time, but it does not match lint/type suppressions. Whether a suppression is legitimate depends on the suppressed rule, and a file crossing 1000 lines needs a base comparison that a PreToolUse hook cannot see.

[nanaism/yomiyasu](https://github.com/nanaism/yomiyasu) offers deterministic Japanese-prose rules the vendored natural-japanese `lint.py` lacks, and a before/after meaning-preservation check (`yomiyasu_diff.py`) with no counterpart here. `lint.py` is vendored byte-for-byte under a no-local-patch policy (`scripts/NOTICE.md`). yomiyasu's own README recommends a CLAUDE.md line that runs it on every Japanese output, which conflicts with `writing-proofread`'s explicit-request-only rule.

## Decision

- Review is split into narrow read-only agents the main session dispatches in parallel: `spec-reviewer` (spec compliance and code quality), `comment-reviewer` (comments and suppressions), `prose-reviewer` (Japanese prose). Each stays narrow so its attention is not diluted; a fixture run showed the combined prompt missing a workaround confession that the focused one caught.
- Every finding carries `encodable: architecture | type | lint | test | hook | rule | none`, the highest level that would stop the class from recurring. `spec-reviewer` defines the scale; the other agents and `adversarial-review` reference it. A class a command can decide without false positives is never `rule`.
- Suppressions and size crossings are detected at review time, not by a hook. A class moves to CI when its `encodable: lint` findings recur and it is shown to be free of false positives.
- `block-rot-comments.py` stays as the zero-cost first pass; `comment-reviewer` covers what a pattern cannot decide.
- yomiyasu's `yomiyasu_lint.py`, `yomiyasu_diff.py`, and `markdown_visibility.py` are fetched unmodified by `home/.chezmoiexternal.toml` from a pinned release tag, not stored in the repo and not ported into `lint.py` (which stays byte-for-byte under its own policy). `yomiyasu_check.py` (writes full-text copies to `.yomiyasu/`) and `yomiyasu_hook.py` are not fetched. The skill's SKILL.md and its "always run" CLAUDE.md line are not adopted.
- The tag is pinned rather than tracking upstream `main`: the scripts run locally under the agent, so a new release enters only through a PR. The weekly `update-yomiyasu` workflow opens that PR, with a GitHub-signed commit and the regression check's output in the body, because CI does not run on PRs opened by `GITHUB_TOKEN`.
- The rot-comment commit gate skips files marked `linguist-vendored` in `.gitattributes`, so byte-for-byte vendored code (natural-japanese `lint.py`) is not forced into local edits.
- `adversarial-review` grades evidence by rung (`said`, `pointed`, `walked`, `ran`, `reproduced`) and records defects that refute no claim under Notes, outside the verdict line.
- Cross-model review (Codex in `adversarial-review` step 1b) is deferred; verdicts already rest on runs, so model diversity matters only at claim enumeration.

## Consequences

- `issue-ship` dispatches the three agents in parallel on every implementer branch, and `workflow.md` makes them the coverage stage for implementer output. This reopens the 2026-10-08 "no extra review rounds" decision by the user's choice. The evidence is narrower than that decision asked for: on a planted fixture, the old single reviewer prompt missed a 1000-line crossing, a workaround confession, and a non-atomic update that the revised and split prompts caught. That compares prompts, not main-session self-review against separate agents; the fixture (a retry change with seven planted defects, judged by a sonnet agent reading each prompt) was a throwaway and is not kept in the repo's tests. The agents run once per issue as one parallel stage, not a round; each spawn costs about 27K tokens for a narrow-tool agent against 176–193K for `general-purpose` (`references/model-profiles/opus-5-5.md`).
- Two Japanese linters overlap on several categories; `prose-reviewer` merges same-line hits rather than either linter being trimmed.
- The yomiyasu regression check downloads the pinned archive, so it runs under `test-skills` (non-hermetic) rather than the CI quality gate; its pinned counts live in `tests/skills/writing-proofread/run-yomiyasu-tests.sh`.
- The bump workflow needs the repository setting that lets GitHub Actions create pull requests.
