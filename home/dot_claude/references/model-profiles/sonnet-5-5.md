# Sonnet 5.5 prompting profile

Model id: claude-sonnet-5-5 Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5 + https://platform.claude.com/docs/en/build-with-claude/effort Distilled: 2026-10-08

Re-distill when the source doc changes or this date is older than ~6 months.

Relevant here because the `implementer`, `spec-reviewer`, and `skeptic` agents run on `model: sonnet`. Load this profile when tuning those agent prompts, not the session model's — after confirming which model the `sonnet` alias currently resolves to (the agent's transcript or `/model` shows it); this file applies only while that is Sonnet 5.5.

## Params (set these, don't reproduce their effect in prose)

- effort: API default `high`; levels are recalibrated vs Sonnet 5. Agentic coding / multistep tool use: `medium` for well-specified tasks, `high` for harder or longer ones. `xhigh`/`max` only for measured gains — at those levels it starts its own review/verification rounds and related fixes. Asking it in prose to think less doesn't reliably work; lower effort instead.
- thinking: lowest setting is `{type: "between_tools"}` (≤ `high` effort only); with it, remove any no-thinking instruction (raises internal-tag leakage).
- max_tokens: 128K for agentic coding, streamed; thinking counts toward it.
- safeguards: `cyber` (finding vulnerabilities in source code is allowed), `bio`, `frontier_llm`, `reasoning_extraction`, `general_harms`.

## Remove — scaffolding this model makes redundant or harmful

| pattern in config                                                           | why remove                                                                                                        |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| "hold all findings for the final response" (when updates should be visible) | suppresses the between-tool notes it writes natively                                                              |
| "only use tools when strictly necessary" / "minimize tool calls"            | on chat and knowledge work it sometimes answers from training knowledge when a search would catch changed details |
| instructions to include reasoning in the response                           | invite `reasoning_extraction` declines; read `display: "summarized"` thinking instead                             |

## Rewrite

| from                                        | to                                                                                                                                                                                                                                                                                                                                                                                                                     | why                                                                                                                                 |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| implicit scope on coding tasks              | "When the work the user asked for is done and checked, stop and report. Don't add features, tests, files, docs or refactors that weren't asked for. If you think one would help, mention it at the end instead of doing it."                                                                                                                                                                                           | it adds tests/docs/small files that fit the repo even unasked, at every effort level, more at higher effort                         |
| implicit carry-through at `low`/`medium`    | "Keep working until everything the user asked for is done, and only stop to ask when you can't go on without the user or before a risky step." (try raising effort first)                                                                                                                                                                                                                                              | at lower effort it checks in before a coding task is done; this makes runs longer and costlier                                      |
| "verify your work"                          | "When you change code that can be run, built, or type-checked, run a real check that exercises the change before reporting it done … A syntax-only check, or a check command that failed to start, does not count; if all that is missing is the project's declared dependencies, install them with its own package manager and lockfile … Only if no real check can run here, say which one you did not run and why." | at `low` it sometimes reports done without a check that exercises the change; the paragraph makes that rare at slightly higher cost |
| self-started review rounds at `xhigh`/`max` | "When the work the user asked for is done and its checks pass, stop and report. Don't start extra rounds of review or hardening on your own, and don't launch reviewer sub-agents unless the user asked for a review. If you think a deeper review is worth doing, say so at the end."                                                                                                                                 | cut session cost ~1/3 at `max` with no quality change                                                                               |

## Keep / add

| pattern                                                                                                                                       | why                                                                                                                                 |
| --------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| deliver mid-turn user input as a user text block after the last `tool_result`, never inside one; harness notices in a separate system message | otherwise it may treat a genuine user message as prompt injection; avoid per-step countdowns after tool results in interactive runs |
| search nudge where a search tool exists: check specifics that may have changed (what is allowed, required, or charged) even when confident    | it answers from training knowledge when a search would catch changes                                                                |
| for the hardest long-horizon work, use an Opus model instead                                                                                  | the guide's own positioning                                                                                                         |
