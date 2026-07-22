# Japanese Writing Quality Harness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repo's accumulated natural-Japanese quality fire at PR/doc moments, from one deduplicated knowledge source, per ADRs 0001–0003.

**Architecture:** Three dependency-ordered PRs. PR-A (ADR 0002) dedups the writing norms into one JIT reference and thins the wrappers. PR-B (ADR 0001 Stage 0) adds JIT injection hooks that point at that reference at the doc/PR moments. PR-C (ADR 0003) codifies the naming convention and renames the writing family. Stage 1/2 of ADR 0001 (deterministic lint guardrail, blocking gate) are out of scope — future work per the ADR.

**Tech Stack:** chezmoi templates, Claude Code hooks (bash + `jq`), markdown skills/rules/references, `bats`-less shell tests (`tests/hooks/*.test.sh` run via `just test`).

## Global Constraints

- Rules / skills / references are written in **English**; Japanese only where a reader-facing template or user-typed trigger phrase requires it (repo `CLAUDE.md`).
- The norms reference **distills** k16shikano's cognitive-rhythm method in house style, **credited** to the source gist — never vendored byte-for-byte (unlicensed gist).
- Every repo-only file needs a `.chezmoiignore` entry or it deploys to `$HOME`. `dot_claude/references/` **is** meant to deploy (skills read it at `~/.claude/references/`); `docs/` and `tests/` are already ignored.
- Every new/extended hook ships a `tests/hooks/*.test.sh`; `just test` must pass.
- Each phase is one PR: effective logic ≤ 300 LOC, one purpose. Commit granularity: 1 logical change per commit.
- Commits are signed. Headless signing uses the on-disk key override: `git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" commit …` (never `--no-gpg-sign`).
- No skill is renamed before PR-C.

---

## PR-A — ADR 0002: knowledge consolidation

Foundational: creates the norms reference PR-B depends on. Content-authoring (markdown, no test framework — TDD exception for declarative/docs content); verification is grep-dedup + `just test`.

### Task A1: Create the canonical norms reference

**Files:**
- Create: `dot_claude/references/japanese-writing/norms.md`

**Interfaces:**
- Produces: the file `~/.claude/references/japanese-writing/norms.md` (post-deploy path) that wrappers and the PR-B hooks point at by that path.

- [ ] **Step 1: Author `norms.md`** with these sections, distilled in house style from the cited sources (do not restate verbatim — synthesize):
  - **Structure** — conclusion-first (source: `technical-writing` "Structure: conclusion first"); one register per document (source: `technical-writing` "Sentence style").
  - **Sourcing / faithfulness** — trace load-bearing claims to source; state inference as inference (source: `technical-writing` "Faithfulness and sourcing").
  - **Rhythm (fingerprint axis)** — sentence-length variety / burstiness, paragraph non-uniformity, avoid ≥3× antithesis (source: `rules/japanese-writing.md` §6).
  - **Cognitive rhythm (structural axis)** — 状況を更新する文 vs 文書を更新する文（dead prose）, hold unresolved tension, dense→sparse alternation, no self-reference to devices. Credit line: "Distilled from k16shikano's cognitive-rhythm-writing method (gist eb2929f…), in house style."
  - **AI-smell taxonomy** — mechanical list templates, hype vocabulary, over-emphasis, English-colon syntax, particle omission (source: `rules/japanese-writing.md` §1–5).
  Keep it a reference (principles + short before/after), not a workflow.
- [ ] **Step 2: Verify it deploys.** Run:
  ```bash
  grep -n "references" .chezmoiignore || echo "references not ignored → deploys (OK)"
  ```
  Expected: prints "references not ignored → deploys (OK)".
- [ ] **Step 3: Commit**
  ```bash
  git add dot_claude/references/japanese-writing/norms.md
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "docs(japanese-writing): add canonical norms reference"
  ```

### Task A2: Thin the always-on rule to a floor + pointer

**Files:**
- Modify: `dot_claude/rules/japanese-writing.md`

- [ ] **Step 1: Trim** the deep rhythm/AI-smell detail that now lives in `norms.md`, leaving a minimal always-on floor: the non-negotiables (avoid AI-smell; particle discipline; active voice) plus a one-line pointer: "Full norms: `~/.claude/references/japanese-writing/norms.md` (loaded JIT by writing skills / injection hooks)." Target: roughly halve the file.
- [ ] **Step 2: Verify no duplicated norm survives in two homes.** Run:
  ```bash
  grep -c "体言止め\|バースト\|状況を更新" dot_claude/rules/japanese-writing.md
  ```
  Expected: `0` (deep rhythm terms now only in `norms.md`).
- [ ] **Step 3: Commit**
  ```bash
  git add dot_claude/rules/japanese-writing.md
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "docs(rules): shrink japanese-writing to always-on floor + norms pointer"
  ```

### Task A3: Point the three wrappers at the norms reference

**Files:**
- Modify: `dot_claude/skills/technical-writing/SKILL.md`
- Modify: `dot_claude/skills/article-writing/SKILL.md`
- Modify: `dot_claude/skills/japanese-ai-writing-proofreader/SKILL.md`

**Interfaces:**
- Consumes: `~/.claude/references/japanese-writing/norms.md` (Task A1).

- [ ] **Step 1: technical-writing** — replace restated norm prose (register, sourcing principle, rhythm) with "Apply the shared norms: `~/.claude/references/japanese-writing/norms.md`." Keep domain-specific tactics (notation tables, procedure shaping, reader-calibration, the before/after examples).
- [ ] **Step 2: article-writing** — in Phase 4/6, point rhythm/style rules at the norms reference; keep phases, gates, style profiles.
- [ ] **Step 3: proofreader** — its AI-smell / naturalness passes reference the norms taxonomy instead of restating; keep tooling (`textlint` / `lint.py`), modes, voice-preservation. Leave it a separate skill (generator-evaluator).
- [ ] **Step 4: Verify each wrapper links the reference and none restates the moved norms.** Run:
  ```bash
  for f in technical-writing article-writing japanese-ai-writing-proofreader; do
    grep -q "references/japanese-writing/norms.md" "dot_claude/skills/$f/SKILL.md" \
      && echo "$f: linked" || echo "$f: MISSING LINK"
  done
  ```
  Expected: all three print "linked".
- [ ] **Step 5: Run full checks.** Run: `just test` — Expected: pass.
- [ ] **Step 6: Commit**
  ```bash
  git add dot_claude/skills/technical-writing/SKILL.md dot_claude/skills/article-writing/SKILL.md dot_claude/skills/japanese-ai-writing-proofreader/SKILL.md
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "refactor(skills): point writing wrappers at shared norms reference"
  ```

---

## PR-B — ADR 0001 Stage 0: JIT injection at doc/PR moments

Depends on PR-A (injects a pointer to `norms.md`). Non-blocking, zero-latency. Hooks need tests.

### Task B1: Extend the PR hook to carry the Japanese-writing pointer

**Files:**
- Modify: `dot_claude/hooks/executable_gh-pr-inject.sh`
- Test: `tests/hooks/gh-pr-inject.test.sh` (create if absent)

**Interfaces:**
- Consumes: existing `gh pr create|edit` detection in the hook.

- [ ] **Step 1: Write the failing test** — assert that for a `gh pr create` command whose `--body` contains Japanese, the emitted `additionalContext` includes `references/japanese-writing/norms.md` and a proofreader reminder; and that an English-only body does NOT add the Japanese pointer.
  ```bash
  # tests/hooks/gh-pr-inject.test.sh — add cases:
  out=$(printf '{"tool_input":{"command":"gh pr create --body \"日本語の本文です\""}}' \
    | "$HOOK")
  echo "$out" | grep -q "references/japanese-writing/norms.md" || fail "no jp pointer on JP body"
  out=$(printf '{"tool_input":{"command":"gh pr create --body \"english only\""}}' \
    | "$HOOK")
  echo "$out" | grep -q "references/japanese-writing/norms.md" && fail "jp pointer leaked on EN body"
  ```
- [ ] **Step 2: Run it, verify it fails.** Run: `bash tests/hooks/gh-pr-inject.test.sh` — Expected: FAIL (pointer not yet added).
- [ ] **Step 3: Implement** — after the existing rule injection, when the command body contains a Japanese codepoint (grep `[぀-ゟ゠-ヿ一-鿿]`), append to `additionalContext` a compact block pointing at `~/.claude/references/japanese-writing/norms.md` and "finish with the japanese-ai-writing-proofreader skill (fix mode) before creating."
- [ ] **Step 4: Run tests, verify pass.** Run: `bash tests/hooks/gh-pr-inject.test.sh` — Expected: PASS.
- [ ] **Step 5: Commit**
  ```bash
  git add dot_claude/hooks/executable_gh-pr-inject.sh tests/hooks/gh-pr-inject.test.sh
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "feat(hooks): inject japanese-writing norms pointer on Japanese PR bodies"
  ```

### Task B2: New doc-injection hook for Japanese `.md` writes

**Files:**
- Create: `dot_claude/hooks/executable_japanese-writing-inject.sh`
- Create: `tests/hooks/japanese-writing-inject.test.sh`
- Modify: `dot_claude/settings.json.tmpl` (wire PreToolUse Write|Edit)

**Interfaces:**
- Consumes: Claude Code hook JSON (`tool_input.file_path`, `tool_input.content` / `tool_input.new_string`).

- [ ] **Step 1: Write the failing test** — a Write to `foo.md` with Japanese content emits `additionalContext` referencing `norms.md`; a Write to `foo.py` with Japanese, or to `foo.md` with English-only, emits nothing.
  ```bash
  out=$(printf '{"tool_name":"Write","tool_input":{"file_path":"doc.md","content":"日本語"}}' | "$HOOK")
  echo "$out" | grep -q "norms.md" || fail "no inject on JP .md"
  out=$(printf '{"tool_name":"Write","tool_input":{"file_path":"x.py","content":"日本語"}}' | "$HOOK")
  [ -z "$out" ] || fail "injected on .py"
  out=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"d.md","new_string":"english"}}' | "$HOOK")
  [ -z "$out" ] || fail "injected on EN .md"
  ```
- [ ] **Step 2: Run it, verify it fails.** Run: `bash tests/hooks/japanese-writing-inject.test.sh` — Expected: FAIL (hook absent).
- [ ] **Step 3: Implement the hook** — guard: `file_path` ends `.md` AND content (`content` or `new_string`) contains a Japanese codepoint → emit `additionalContext` pointing at `norms.md` + proofreader reminder. Fail closed to silence (exit 0, no output) on any non-match or error.
- [ ] **Step 4: Wire it** in `dot_claude/settings.json.tmpl` under `PreToolUse` matcher `Write|Edit` (alongside `block-rot-comments.py`).
- [ ] **Step 5: Run tests, verify pass.** Run: `bash tests/hooks/japanese-writing-inject.test.sh` then `just test` — Expected: PASS.
- [ ] **Step 6: Commit**
  ```bash
  git add dot_claude/hooks/executable_japanese-writing-inject.sh tests/hooks/japanese-writing-inject.test.sh dot_claude/settings.json.tmpl
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "feat(hooks): JIT japanese-writing norms injection on Japanese .md writes"
  ```

---

## PR-C — ADR 0003: naming convention + writing-family rename

Independent of PR-A/B in content; ordered last so it sweeps their cross-references in one pass.

### Task C1: Record the naming convention

**Files:**
- Create: `dot_claude/rules/skill-naming.md` (or append to an existing conventions rule if one fits)

- [ ] **Step 1: Write** the convention: kebab-case `<subject>-<role|action>`, subject-first; families of ≥2 share a leading stem; guessable names; migration = lazy (rename on next substantive touch) + convention-for-new. Include the rename map table from ADR 0003.
- [ ] **Step 2: Ensure it does not deploy as an always-on global rule if that is unwanted** — confirm placement matches other `dot_claude/rules/` files (these deploy to `~/.claude/rules/`). Note in the file it is a convention doc, not an always-on behavioral rule.
- [ ] **Step 3: Commit**
  ```bash
  git add dot_claude/rules/skill-naming.md
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "docs(rules): add skill naming convention"
  ```

### Task C2: Rename the writing family + sweep references

**Files:**
- Rename: `dot_claude/skills/technical-writing/` → `writing-technical/`
- Rename: `dot_claude/skills/article-writing/` → `writing-article/`
- Rename: `dot_claude/skills/japanese-ai-writing-proofreader/` → `writing-proofreader/`
- Modify: each SKILL.md `name:` frontmatter; all cross-references (the two generators' proofreader pointers, `article-writing`↔`japanese-ai-writing-proofreader` mentions, ADRs 0001–0003, memory, `CLAUDE.md`, `tests/skills/**`).

- [ ] **Step 1: Rename dirs and update `name:` frontmatter** for all three. `git mv` each; update the `name:` field to match the new directory.
- [ ] **Step 2: Sweep every reference.** Run:
  ```bash
  grep -rln "technical-writing\|article-writing\|japanese-ai-writing-proofreader" \
    --include="*.md" --include="*.tmpl" --include="*.sh" . | grep -v '/\.git/'
  ```
  Update each hit to the new name. Re-run until only intended historical mentions (e.g. ADR prose describing the old name) remain.
- [ ] **Step 3: Verify the renamed skills still resolve** — `just test` (skill-script tests) passes; grep confirms no dangling old invocation names in live config/hooks.
- [ ] **Step 4: Commit**
  ```bash
  git add -A
  git -c gpg.ssh.program=ssh-keygen -c user.signingkey="$HOME/.ssh/id_ed25519.pub" \
    commit -m "refactor(skills): rename writing family to writing-* per naming convention"
  ```

---

## Self-Review

- **Spec coverage:** ADR 0002 → PR-A (A1 norms, A2 floor, A3 wrappers). ADR 0001 Stage 0 → PR-B (B1 PR hook, B2 doc hook); Stage 1/2 explicitly deferred. ADR 0003 → PR-C (C1 convention, C2 rename). Covered.
- **Placeholder scan:** norms/rule/convention *content* is authored at execution from cited sources — that is a deliverable, not a placeholder; the plan fixes sections, sources, and verification for each.
- **Type/name consistency:** hook file names (`executable_japanese-writing-inject.sh`), reference path (`~/.claude/references/japanese-writing/norms.md`), and new skill names (`writing-technical/-article/-proofreader`) are used consistently across tasks.
- **Ordering:** PR-A before PR-B (B injects A's path); PR-C last (sweeps A/B refs). Signed-commit override applied in every commit step.
