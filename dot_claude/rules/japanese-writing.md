---
alwaysApply: true
---

# Japanese Writing

When producing Japanese prose (responses, PR bodies, commit messages, docs), avoid the
following "AI smell". The instructions below are in English; the target vocabulary and
example sentences stay in Japanese because they are what the rule operates on.
Reference: [textlint-rule-preset-ai-writing](https://github.com/textlint-ja/textlint-rule-preset-ai-writing)

## 1. Mechanical list formatting

Avoid:

- A fixed `**ラベル**: 説明` template applied to every item
- Mechanical use of emoji markers (✅ ❌ 💡 🎯 🚀)
- Forcing the same structure onto every bullet

→ Use prose where prose works. If you must list, keep granularity and structure
consistent but drop the boilerplate labels.

## 2. Hype / exaggeration

Avoid: 「革命的」「画期的」「世界初」「魔法のような」「パラダイムシフト」「劇的に向上」「圧倒的」「究極の」「最強の」「次世代」

→ Replace with concrete numbers, facts, and comparisons.

## 3. Excessive emphasis

Avoid:

- Bolding adverbs（`**非常に**`、`**極めて**`、`**かなり**`）
- Leading every heading with an emoji
- Repeated 「！」

→ Emphasize only the single point that truly matters. If the meaning carries on its own,
don't decorate it.

## 4. English-style colon syntax

Avoid placing `:` right after a clause that ends in a predicate (verb/adjective).
例: ❌「これは便利です: 〜」「実装した: 〜」

→ Receive with a noun before `:`, or break with a newline/period.
例: ✅「便利な点は次のとおり: 〜」「〜を実装した。具体的には〜」

## 5. Technical writing

- Don't omit particles (助詞). Prefer 「ファイルを作成する」 over 「ファイル作成」,
  「設定を変更する」 over 「設定変更」. Particles fix meaning in Japanese; omitting them
  makes the dependency structure ambiguous.
- Prefer active over passive voice（「〜される」→「〜する」）
- Compress redundancy（「〜することができる」→「〜できる」、「〜を行う」→ verb form）
- Consider splitting any sentence over 80 characters
- No subject–predicate disagreement
- Unify terminology within a document（「サーバ／サーバー」 etc.）

## Scope

- Applies to Japanese that Claude outputs
- Don't proofread the user's Japanese input (only on request, via the
  `japanese-ai-writing-proofreader` skill)
