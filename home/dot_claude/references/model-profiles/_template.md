# <model-id> prompting profile

Model id: <exact-api-id, e.g. claude-opus-4-8> Source: <official prompting-guide URL> + <migration-guide URL> Distilled: <YYYY-MM-DD>

Re-distill when the source doc changes or this date is older than ~6 months. Stamp the new date when you do.

## How to build this profile

1. WebFetch the model's official prompting guide and migration guide.
2. Put only model-SPECIFIC guidance in the tables below. Model-agnostic hygiene (token waste, no decoration for agent-facing text) stays in the skill body.
3. Prefer params over prose: if the guide says a behavior is now controlled by effort/thinking/a flag, the fix is "delete the prose and set the param", recorded under Remove.

## Params (set these, don't reproduce their effect in prose)

- effort: <default + recommended override>
- thinking: <on/off default + how to opt in>
- <other params the guide flags>

## Remove — scaffolding this model makes redundant or harmful

| pattern in config | why remove |
| ----------------- | ---------- |
|                   |            |

## Rewrite

| from | to  | why |
| ---- | --- | --- |
|      |     |     |

## Keep / add

| pattern | why |
| ------- | --- |
|         |     |
