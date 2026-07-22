# Opus 4.8 prompting profile

Model id: claude-opus-4-8 Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8 + https://platform.claude.com/docs/en/about-claude/models/migration-guide Distilled: 2026-07-03

Re-distill when the source doc changes or this date is older than ~6 months.

## Params (set these, don't reproduce their effect in prose)

- effort: default `high` on all surfaces incl. Claude Code; set `xhigh` explicitly for coding / high-autonomy work.
- thinking: off by default — requests without a `thinking` field run without thinking. Opt in with `thinking: {type: "adaptive"}`; the trigger is steerable by prompt.
- sampling: `temperature`/`top_p`/`top_k` must stay default (non-default → 400).
- context: 1M window is the default; drop any context-window beta header.

## Remove — scaffolding this model makes redundant or harmful

| pattern in config                                                                 | why remove                                                                                            |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| forced interim updates ("after every 3 tool calls, summarize progress")           | 4.8 gives calibrated, higher-quality progress updates natively                                        |
| prose reasoning scaffolds ("think step by step", "reason carefully first")        | reasoning depth is controlled by effort/thinking params, not prose; raise effort instead              |
| forced verbosity or length padding                                                | 4.8 calibrates length to task complexity on its own                                                   |
| heavy anti-"AI slop" frontend preamble                                            | 4.8 avoids generic design with minimal guidance                                                       |
| "only report high-severity", "be conservative", "don't nitpick" in review prompts | 4.8 follows this literally and drops real low-severity bugs; separate coverage from filtering instead |

## Rewrite

| from                                      | to                                                                                                              | why                                                                |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| implicit scope ("apply this rule")        | explicit scope ("apply to every section, not just the first")                                                   | 4.8 is literal and does not generalize an instruction across items |
| negative bans ("don't be verbose")        | positive target ("one line per finding; minimal examples")                                                      | positive examples steer 4.8 better than negative instructions      |
| qualitative bar ("report important bugs") | concrete bar ("report bugs causing wrong behavior, test failure, or misleading output; omit pure style/naming") | literal following needs a concrete threshold, not a vibe           |
| hardcoded model name in subagent dispatch | inherit the session model; name a model only for a mechanical substep                                           | avoids re-migrating every prompt when the next model ships         |

## Keep / add

| pattern                                                                   | why                                                                 |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| explicit subagent-spawning guidance (when to fan out vs. do inline)       | 4.8 spawns fewer subagents by default; state when fan-out is wanted |
| "report every finding; a later stage filters for severity/confidence"     | moves confidence-filtering out of the finding step, raising recall  |
| effort `xhigh` for coding/agentic; large max-output budget at high effort | best settings per guide for capability and room to act              |
