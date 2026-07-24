# Opus 5 prompting profile

Model id: claude-opus-5 Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 + https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5 + https://platform.claude.com/docs/en/build-with-claude/effort + https://platform.claude.com/docs/en/about-claude/models/migration-guide Distilled: 2026-07-25

Re-distill when the source doc changes or this date is older than ~6 months.

## Params (set these, don't reproduce their effect in prose)

- effort: default `high`; start `xhigh` for coding/agentic work. `low`/`medium` are unusually strong on this model — use them as the primary cost/latency lever, and re-run an effort sweep instead of carrying prior-model defaults. At `xhigh`/`max`, set `max_tokens` ≥ 64K.
- thinking: ON by default — omitting `thinking` runs adaptive (opposite of 4.8, where omitting meant off). `{type: "disabled"}` is accepted only at effort `high` or below; pairing it with `xhigh`/`max` → 400. Prefer thinking on + lower effort over disabling — disabled thinking can emit tool calls as plain text (silently never run) and leak `<thinking>` tags.
- verbosity: effort controls thinking volume, NOT visible response length. Prompt for length explicitly; lowering effort does not reliably shorten output.
- sampling: `temperature`/`top_p`/`top_k` must stay default (non-default → 400), unchanged from 4.8.
- context: 1M window is both default and maximum; prompt-cache minimum drops to 512 tokens (re-check prompts written off as uncacheable on 4.8); separate rate-limit bucket from the combined Opus 4.x pool.

## Remove — scaffolding this model makes redundant or harmful

| pattern in config                                                                          | why remove                                                                                     |
| ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| verification instructions ("include a final verification step", "use a subagent to verify") and separate harness verification stages | 5 verifies its own work unprompted; these cause over-verification — delete, don't rewrite       |
| self-check phrasing ("double-check your answer", "re-verify before responding")            | same trap; inverts the usual ask-Claude-to-self-check best practice — prompt libraries need a carve-out |
| "delegate more" / subagent-spawning encouragement added for 4.8                            | 5 over-delegates by default — the 4.8-era nudge multiplies cost; replace with a cap (see Keep/add) |
| forced interim updates ("after every 3 tool calls, summarize progress")                    | 5 narrates even more than 4.8 natively; scaffolding compounds the verbosity                     |
| don't-think / don't-reason rules on thinking-disabled routes                               | they *increase* `<thinking>`-tag leakage rather than suppressing it                             |

## Rewrite

| from                                        | to                                                                                                                             | why                                                                                    |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| shortening output by lowering effort        | explicit conciseness instruction, plus a short `<tone_preference>` reminder near the end of long system prompts                | effort doesn't shorten visible output; a short instruction cut response length ~20%     |
| free-form agentic narration                 | describe the cadence: one sentence before the first tool call; brief updates only on findings or direction changes; final message leads with the outcome | 5 narrates readily; explicit shape steers it both down and up; positive examples beat "don't" lists |
| implicit task scope                         | scope-discipline instruction: deliver what was asked at the intended scope, make routine judgment calls yourself, finish the whole task, flag a better approach in one sentence and continue | 5 expands scope and adds unrequested steps; this wording reduced scope changes to near zero |
| unconstrained self-correction narration     | correct only errors that change the user's code, conclusions, or decisions; fix immaterial slips silently                      | 5 narrates its corrections at length, which reads as thrash in user-facing products     |

## Keep / add

| pattern                                                                                     | why                                                                                     |
| ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| deterministic subagent cap + delegate only for large, genuinely independent tracks; never subagents for verification | direction flip from 4.8 (which under-delegated); a spawn-count ceiling is the reliable lever |
| "report every finding; a later stage filters for severity/confidence" in review prompts     | unchanged from 4.8: severity filters are followed literally and depress measured recall  |
| deliverable-length calibration for Claude-authored files (cover substance, no filler sections or boilerplate) | files written to disk run longer than on prior models, independently of chat verbosity   |
| full task specification up front in a single turn for agentic runs                          | strongest results on long autonomous sessions; drip-feeding requirements underperforms   |
| vision: give crop/analyze/verify tools instead of raising thinking                          | tool use is the more cost-effective vision lever on this model                           |
| on must-stay-disabled thinking routes: "you may say a brief sentence before using a tool" + generic "do not include internal or system XML tags" (never name thinking tags) | mitigates text-leaked tool calls and tag leakage; naming the tags is measurably less effective |
