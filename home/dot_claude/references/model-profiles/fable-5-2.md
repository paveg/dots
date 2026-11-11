# Fable 5.2 prompting profile

Model id: claude-fable-5-2 (sibling claude-mythos-5-2: same capabilities, verified orgs only) Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2 + https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2 Distilled: 2026-11-11

Re-distill when the source doc changes or this date is older than ~6 months. The migration guide (https://platform.claude.com/docs/en/models/fable-5-2/migration-guide) was not read for this distillation.

Relevant here because `skeptic` runs on `model: fable` and `advisorModel` is `fable`. Load this profile when tuning the skeptic prompt, after confirming the `fable` alias resolves to Fable 5.2; this file applies only while it does.

## Params (set these, don't reproduce their effect in prose)

- effort: API default `high`; set it explicitly, then eval at `medium` and `xhigh` too. Rerun the sweep — don't carry over a level tuned on Fable 5.1 or Opus 5.5. `low` scores close to Fable 5.1 at higher effort (fast subagents, high volume); `medium` for interactive coding/chat; `high` for hard coding, research, long unattended runs — most of the capability gain is already there; `xhigh` only for a measured gain (slightly higher scores, many more tokens); `max` for ceiling measurement. Effort changes how the model thinks and how many tool calls it makes, but barely changes reply length — set length and tone in the prompt. Early stopping is more likely at lower effort. Per-message effort change keeps the cache (beta `mid-conversation-output-config-2026-07-01`); a new top-level value restarts it.
- thinking: adaptive, always on. `{"type": "enabled", budget_tokens}` and `{"type": "disabled"}` return 400; omit `thinking` or send `{"type": "adaptive"}`. At `high`+ it thinks before almost every reply, greetings included.
- thinking display: progress updates between tool calls arrive as `thinking` blocks, empty under the default `"omitted"`. Set `"updates"` (beta `thinking-display-updates-2026-08-18`) or `"summarized"` and render non-empty thinking blocks, or a client that renders only `text` looks silent.
- tool_choice: forced tool use (`any` / named tool) returns 400. For schema-valid JSON keep `auto` + `strict: true`, or JSON outputs. Under CMEK neither strict tool use nor JSON outputs is available: leave out `strict` and validate the tool input in code.
- history: append-only, now enforced on every account (5.1 only enforced it for accounts created on/after 2026-08-31). Any change to `system`, `tools`, or an earlier message before a thinking block → the Messages API rejects with 400 "The block is bound to a different conversation" (the Message Batches API drops those blocks instead). `prefix_mismatch_behavior: "drop_block"` (beta `thinking-binding-controls-2026-08-01`) is a stopgap — dropped thinking gets regenerated and raises output tokens. Change instructions in the newest turn or a mid-conversation system message; shorten history only via context editing or compaction that keeps no earlier turns after the summary (on-demand: beta `compact-2026-09-04`); add/remove tools in a system message (beta `inline-tools-2026-09-15`). Leave reminders in place on later requests.
- cross-model: on the Claude API and Google Cloud (Google managed), 5.2 reads thinking from older models. No non-5.2 model reads 5.2's thinking — switching away (to Opus 5.5, Fable 5.1, fallbacks) loses it silently.
- advisor: a Fable 5.2 executor accepts only `claude-fable-5-2` / `claude-mythos-5-2` as advisor (5.1 → 400); every executor accepts `claude-fable-5-2`. Changing the advisor model edits `tools`, so do it in a new conversation.
- computer use: `computer_20251124` returns 400 outside Bedrock; use `computer_toolset_20260801`.
- refusals: HTTP 200 with `stop_reason: "refusal"` and `stop_details.category` (`cyber`, `bio`, `frontier_llm`, `reasoning_extraction`, `general_harms`). Server-side `fallbacks: "default"` has no recommended fallback for `reasoning_extraction`, so that refusal stands.
- silent-stretch reminder (harness side): turn-scoped system message with `clear_at: "next_user_message"` (beta `mid-conversation-system-clear-at-2026-08-21`) after several silent tool steps: "The user hasn't heard from you in a while: say in a few words what you're doing, then continue." It roughly halved the longest silent stretch with no noticeable token or time cost. Count silent steps with thinking display set to `"updates"` or `"summarized"`.

## Remove — scaffolding this model makes redundant or harmful

| pattern in config | why remove |
| --- | --- |
| "answer directly without deliberating" / other think-less lines | 5.1 usually followed them; 5.2 keeps thinking at `medium`+. Delete the line and lower effort |
| prompts, skills, or tool descriptions asking the model to write out its reasoning in the reply | can trigger `reasoning_extraction` refusals (the category covers requests to reproduce internal reasoning in the response text). Use `display: "summarized"` and read thinking blocks instead |
| standing "delegate to subagents" instructions (system prompt, skills, agent files) | in an agentic coding product whose prompts invite delegation, 5.2 delegates readily (with a minimal subagent tool on short tasks it rarely does), and at `xhigh`/`max` it spawns subagents to review its own work (5.1 didn't). Remove them if it over-delegates |
| a token budget the harness writes into the prompt | the stated size steers spend; removing a large budget at `high`/`xhigh` lowered cost with equal performance (API task budgets were not tested) |
| hard style limits (e.g. "one instruction per sentence, in 20 words or fewer") | 5.2 follows style rules closely, and a hard limit can make its prose choppy. Remove before adding the communicating-clearly block |
| cautions whose reason no longer holds, including what reviewer agents attach to the context | cautions pile up: in one tested setup only 5.2 held back — with a reviewer's "stop at the first error" in context it skipped retries in ~1/3 of tries where 5.1 and Opus 5.5 retried. A dozen notes, one saying never to retry, cut retries-after-busy from nearly all tries to ~4/10 |
| Opus 5.5 "treat that answer as done" chat lines | they cut follow-up thinking but make 5.2 far less likely to point out mistakes in earlier answers. Leave out where re-examination matters |
| harness code that edits earlier turns | breaks the prefix check (Params → history) |

## Rewrite

The absolute-rules row is a pre-migration review. Apply the other rows only after observing the behavior they target, one fix at a time, measuring the effect and token cost.

| from | to | why |
| --- | --- | --- |
| absolute rules with no stated scope | state the scope and the reason in the rule | the guide's remedy for caution pile-up: delete cautions whose reason no longer holds, rewrite the absolute ones |
| approval rules by category (one rule listed "sending messages to people outside this conversation" among steps needing approval) | name the exact actions the rule covers | 5.2 applies approval rules as written: that rule held back ~half of routine requests to colleagues |
| a "never" rule plus a separate line saying an approved step has its go-ahead | put the exception into the rule itself, e.g. the rule says to get a go-ahead first | under the "never" rule the model took the approved step in ~1/10 tries and the separate line barely changed that; with the rule itself saying to get a go-ahead first, ~9/10 |
| "act more freely" / general permission | list the steps that need no approval, e.g. retries of calls that are safe to repeat | listing retries raised them from almost none to ~half of tries; the general instruction changed nothing |
| bare "continue" / "go" approvals | an explicit go-ahead naming the action ("Yes, run the migration on the staging database") | the guide's own advice for telling the model to keep going; it gives no measured effect |
| "don't stop early" / "keep going" | the `# Finishing work` block from the prompting guide: avoid stopping while work is owed; carry on with work that doesn't depend on the user's answer; diagnose ordinary obstacles (errors, timeouts, locked files, empty results, failing tools) and work through them; leave deliberate blockers (a file marked not to be touched, withheld access, a safety guardrail) alone and say so; this does not override confirmation on risky or destructive actions. Keep your own confirmation step for risky or irreversible actions — the model asks less with this text | 5.2 sometimes ends a turn early with a list of what remains, an offer to continue, or a stop at an ordinary obstacle, more at `low`/`medium`. At `medium` the block halved sessions ending with doable work left and removed most offer-to-continue endings (not list-what-remains endings); output tokens +~30% |
| "write concisely" for final reports / handoffs | the `# Communicating clearly` block: write for an intelligent, low-context reader who has not seen the tool calls; key points first, progressive disclosure; plain words, no terms coined during the work; mostly ASD-STE100 Simplified Technical English (short sentences, one idea each, active voice, same word for the same thing); prose where ideas connect, bullets for separate items | made reports less dense with fewer semicolons; adjust to the readers and add length rules if needed |

## Keep / add

| pattern | why |
| --- | --- |
| ownership line when structural improvement is wanted: "This codebase is yours: what it's for and how it's built are your call, and you'll keep building on it." Leave it out where the user owns the code and wants minimal change | without it (or with code framed as someone else's) 5.2 adds to the existing structure even when that repeats code, and reports nearby problems instead of fixing them. With it, it merged repeated code in ~1/2 of tries vs < 1/10. Cost: ~1.5× output, unrequested tests/docs, changed existing behavior in 1/10–1/6 tries; a "no drive-by refactors" rule only cut merges to ~1/3, and the summary often omits small changes — review the diff |
| progress cadence where a human is in the loop: "Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own (what you found, what you did, and what's next), so a reader who only sees the last message has the full picture." | 5.2 can write little user-facing text in long tool runs and make its first call unannounced. With this line it spoke before the first tool call every time; output +~20% |
| without harness access: "Every few tool calls, give the user a one-line update on where things stand." | cut most long silent stretches on workflow-automation tasks |
| subagent tool description that states cost first, when delegation is and isn't worth it, and how to brief — only after reviewing delegation lines in prompts/skills/agents, and only if it still over-delegates | delegation fell ~1/3 vs a description that mostly listed reasons to delegate, with no change in task success. Also check which model the harness runs subagents on by default |
| 5.2 as planner / orchestrator over other models | early testers had good results with this split |

## Already supplied by the Claude Code harness

Documented: requests that Claude Code builds already satisfy the append-only prefix check, so nothing in rules needs to manage history. Observed in an Opus 5.5 session (see `opus-5-5.md`), not re-checked under Fable 5.2: the turn-scoped "The user hasn't heard from you in a while" reminder, which is the guide's harness-side fix for silent stretches. Nothing else in this profile has been checked against what the Claude Code harness supplies.
