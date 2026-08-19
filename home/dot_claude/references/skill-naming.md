# Skill Naming Convention

Loaded just-in-time when creating or renaming a skill — not an always-on rule (it would spend the always-on instruction budget for a rule that rarely applies; see `rules/harness-meta.md`).

## Convention

- kebab-case, **subject-first**: `<subject>-<role|action>`. The subject a reader would search for leads; the role/action follows.
- A **family of ≥2 skills sharing a subject uses a shared leading stem** so the family clusters in the sorted skill list (`writing-*`, `decision-*`).
- Keep one consistent action form within a family (bare stem or gerund, not both).
- Names stay guessable: avoid bare single words that don't say what the skill does.

## Migration

Renames are breaking (Claude Code skills have no alias — every invocation, cross reference, and memory entry must move at once), so migrate lazily:

- Apply the convention to **all new skills** immediately.
- Rename an existing skill **only when it is next substantively touched**, sweeping every reference (skills, rules, hooks, tests, memory) in that change.

## Rename map (target names; execute per migration above)

| Current                           | Target                           |
| --------------------------------- | -------------------------------- |
| `technical-writing`               | merged into `writing` (ADR 0007) |
| `article-writing`                 | merged into `writing` (ADR 0007) |
| `japanese-ai-writing-proofreader` | `writing-proofread` (ADR 0007)   |
| `equity-decision`                 | `decision-equity`                |
| `ipo-decision`                    | `decision-ipo`                   |
| `feature`                         | `feature-workflow` (optional)    |
| `empirical-prompt-tuning`         | `prompt-tuning` (optional)       |

Skills not listed already conform; keep their names. Full rationale and the global survey: `docs/adr/0003-skill-naming-convention.md`.
