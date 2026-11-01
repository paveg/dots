# 0010. Review word-level naturalness in a separate read-only agent, with editable yomiyasu word lists

## Status

Accepted — 2026-11-01. Effectiveness is not yet measured.

## Context

The user reports wording discomfort that survives both linters: literal translation, stiff kanji compounds, skewed noun and verb pairings, and sentences whose subject and predicate do not hold together. The writer reads its own words by intent, so it does not notice them, and `lint.py` (natural-japanese) and `yomiyasu_lint.py` operate on sentences and fixed word lists.

yomiyasu was fetched (ADR 0009) but only `prose-reviewer`, which runs on every `issue-ship`, used it; `writing-proofread` did not. natural-japanese v1.6.4 ships `calques.py` and a set of reading tests in its SKILL.md that target exactly this class, but `calques.py` is noisy (most hits are literal uses or settled terms), and printing its output, which includes the whole paragraph per hit, would spend main-session context.

A July measurement rejected delegating the whole proofread to sonnet-5: 65 points against 77-82 for opus (see `.ai/japanese-proofreader-token-tuning.md` in the main checkout, if present). Judgment stays in the main session.

## Decision

- A separate read-only Sonnet agent, `wording-reviewer`, runs `calques.py` and the relevant `yomiyasu_lint.py` rules, applies the back-translation, noun-to-verb, collocation, stiff-compound, subject-predicate, and vague-wording tests, and returns at most 15 candidates. The main session adjudicates each under `writing-proofread`'s scope guards and applies the fixes. The agent never edits.
- Narrow timing: Pass 5 of `writing-proofread` runs once, in fix mode, on articles and standalone documents after Passes 1-4, or on an explicit word-choice request. PR bodies, commit messages, and short text never get it.
- The `allow.txt` and `flag.txt` word lists live in `writing-proofread/assets/yomiyasu-words/` and reuse yomiyasu's `--words` format, so one editable file drives the linter. The allow list moved out of the norms prose into `allow.txt`; the norms point to it. `prose-reviewer` passes the same directory.
- yomiyasu's `slop-catalog.md` is fetched by the existing chezmoi external instead of distilled into this repo. The agent reads it once, only to judge a borderline candidate, so a version bump refreshes it with the scripts.
- `calques.py` is vendored byte-for-byte from natural-japanese v1.6.4 under the existing no-local-patch policy. Its lack of an allow option is handled by the agent reading `allow.txt`.

## Rejected or deferred

- Extending `prose-reviewer`: it runs on every `issue-ship`, and word-level review is a heavier, document-level pass that most diffs do not need.
- A BCCWJ frequency detector for stiff words: add it when the agent demonstrably misses stiff words and the corpus licensing is checked.
- A surprisal lint: no significant correlation with fluency in Japanese was found ([Tamura 2023](https://www.anlp.jp/proceedings/annual_meeting/2023/pdf_dir/A9-4.pdf)).

## Consequences

- One more Sonnet spawn per article proofread, outside the `issue-ship` coverage stage.
- Effectiveness is not measured: no run has compared drafts with and without Pass 5. Revisit after real articles show whether candidates are accepted or mostly dropped.
- The agent's tests are distilled from natural-japanese SKILL.md v1.6.4, so a later upstream change does not reach them without a manual update.
- `tests/skills/writing-proofread/` pins the word lists (`正本` flagged, `土台` allowed) and the `calques.py` detector; the agent's judgment itself has no deterministic check.
