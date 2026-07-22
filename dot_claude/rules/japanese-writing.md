# Japanese Writing

When producing Japanese prose (responses, PR bodies, commit messages, docs), avoid
"AI smell" and keep the sentence structurally sound. The instructions below are in
English; the target vocabulary stays in Japanese because it is what the rule operates on.

## Non-negotiables

- Don't omit particles (助詞). Prefer 「ファイルを作成する」 over 「ファイル作成」,
  「設定を変更する」 over 「設定変更」. Particles fix meaning in Japanese; omitting them
  makes the dependency structure ambiguous.
- Prefer active over passive voice（「〜される」→「〜する」）
- Avoid AI smell: mechanical list templates, hype vocabulary, over-emphasis, and
  English-style colon syntax right after a predicate. Full taxonomy in the norms
  reference below.

Full norms: `~/.claude/references/japanese-writing/norms.md` (loaded JIT by writing
skills / injection hooks) — structure, sourcing, rhythm, cognitive rhythm, and the
complete AI-smell taxonomy live there.

## Scope

- Applies to Japanese that Claude outputs
- Don't proofread the user's Japanese input (only on request, via the
  `japanese-ai-writing-proofreader` skill)
