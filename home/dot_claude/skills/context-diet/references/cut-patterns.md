# Cut Patterns

What to compress, what to move, what to leave alone. Read this before writing edits; the classification in SKILL.md tells you _where_ the cost is, this file tells you _what_ to do about it.

## Cut outright

**Restated model defaults.** Anything the model already does without being told. "Match the user's input language" duplicates the harness `language` setting. "Use Go template syntax `{{ .variable }}`" restates what reading one template file teaches. These pass the named-failure test trivially: there is no failure they prevent, because the behavior happens anyway. If you suspect otherwise, that suspicion is itself the test case — run it before cutting.

**Rationalization tables.** The `| "This is too simple to test" | Simple code breaks too |` format was built for models that argued their way out of constraints. Newer models do not need the counter-argument spelled out, and the table costs 6–10 lines to say what one line says. Keep the constraint; drop the debate. If the rationalizations are historically interesting, move them to `references/` as a record, not a rule.

**Duplicated facts.** The same warning in CLAUDE.md, a rule, and a memory file is three places to update and one place where they will drift apart. Pick the layer whose loading trigger matches when the fact is needed, delete the rest, and repoint any `[[wiki-links]]`.

**Absolute commands that the harness contradicts.** "For every non-trivial task, do X" loses to a harness default that says otherwise, and the model pays to resolve the conflict on every turn. Rewrite as a criterion the model can apply, or delete it.

## Compress, don't delete

**Guardrails on irreversible actions.** Force-push, `rm -rf`, secret writes, production migrations. The wording can shrink; the constraint stays. Better: check whether a PreToolUse hook already enforces it mechanically — if so, the prose only needs to cover the judgment the hook cannot make.

**Three-condition conjunctions.** "Only do X when ALL of: A, B, C" is usually one condition wearing three hats. Find the condition that actually decides and state it.

**Trigger lists in descriptions.** Four Japanese trigger phrases beat eight. Keep the ones a user would actually type; drop the paraphrases.

## Move to `references/`

**Worked examples longer than ~15 lines.** A full prompt template, a PR body layout, a sample config. The blog-era instinct was that examples teach; the current problem is that a long example anchors the model to that exact shape. Leave the interface in the body (what the prompt must contain) and put the worked instance in `references/`.

**Measurement machinery.** Axis definitions, scoring rules, reporting formats. Needed at one step, not while deciding whether to proceed.

**Phase content in a skill whose phases are skippable.** If the skill itself documents "skip phases 0–3 when the user already has the list", those phases belong in a separate file.

## Leave alone

**Negative triggers in a `description`.** "Never fire proactively on PR bodies" only works where the loading decision is made. Moving it into the body means the skill has already loaded before reading it.

**Sibling disambiguation.** "Article mode vs technical mode routes inside writing; proofreading goes to writing-proofread." This is what stops the wrong skill from firing, and it costs one sentence.

**Measured numbers.** "Three agents that did nothing burned 114K tokens." A number that came from a real run is the reason a rule exists; without it the rule reads as taste and gets ignored.

**Project-specific gotchas.** The non-obvious constraint that makes the model write wrong code — a build step that must run first, a config file that is regenerated, a directory that is deployed by default. This is the content CLAUDE.md exists for.

## Sequencing

Compress before splitting. A `references/` split of text that should have been deleted just moves the problem, and the pointer line you leave behind costs something too. Delete, then compress what survives, then split what is still large and genuinely staged.

Splitting last is also the safer order for quality. A split is the one move whose failure is silent — the content still exists, so nothing looks wrong until a run needs it and the pointer does not fire. Doing it after the deletions and compressions have been verified means a regression that appears at this stage has only one candidate cause.
