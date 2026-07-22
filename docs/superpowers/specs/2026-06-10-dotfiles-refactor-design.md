# Dotfiles Refactor — Design

Date: 2026-06-10 Status: Approved

## Goal

Improve readability, maintainability, and performance of the dotfiles repo without changing behavior. Work is split into five independent PRs (one purpose each, effective logic ≤ 300 LOC). Implementation is dispatched to worktree-isolated subagents; the main session reviews each diff (generator-evaluator separation). Push and PR creation happen only after explicit user confirmation.

## Audit Provenance

Three parallel audit agents surveyed zsh, chezmoi/CI, and misc configs; a fourth surveyed `dot_claude/rules` + `skills`. Findings were manually verified before inclusion. Rejected as false positives:

- "git config values must be quoted" — git INI values read to end-of-line; spaces are fine
- "`$osID` is unused" — emitted as `osid:` in `.chezmoi.yaml.tmpl:38`
- "move devbox shellenv from zshenv to zshrc" — non-interactive shells need devbox PATH; placement is intentional

User decisions:

- Keep the `brew shellenv` eval in `dot_zprofile.tmpl` (business-only; cannot be verified on this machine)
- Delete `rules/browser-automation.md` (duplicate of guidance embedded in the `browser-e2e-test` skill; rule-budget saving accepted over always-loaded coverage)

## PR 1 — zsh cleanup (`refactor/zsh-cleanup`)

1. Add the 4-line header convention (`Provides:` / `Requires:` / `Side-effects:` / `Load-order:`) to the 8 feature files missing it: `branch-cleanup.zsh`, `cache-mgmt.zsh`, `devbox-brew.zsh`, `documentation.zsh`, `dotfiles-helpers.zsh`, `kube.zsh`, `local-config-cmd.zsh`, `profiling.zsh`. Follow the format used by `features/git-branch-fzf.zsh`.
2. Fix the misleading `Load-order:` header in `init/plugins.zsh` (currently says "BEFORE options" in a self-contradictory way; describe actual order: after perf-flags, provides zinit consumed by options.zsh and features).
3. Define `export ZSH_INIT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init"` in `init/xdg.zsh` and replace all 9 hardcoded `…/zsh/init` occurrences: `init/homebrew.zsh.tmpl:12`, `init/mise.zsh:10`, `init/plugins.zsh:90,96,109,122,157`, `features/cache-mgmt.zsh:3,14`. Producer and consumer (rm -rf in cache-mgmt) must use the same variable.
4. Guard the redundant `compinit -C` in `modules/bun.zsh` so it is skipped when compinit has already run (e.g. `(( $+functions[compdef] ))` check).

Out of scope: `dot_zprofile.tmpl` brew eval (kept), moving abbreviations out of `plugins.zsh` (LOW, deferred).

Verification: `just test`; render templates and `zsh -n` each file; interactive startup smoke (`zsh -i -c exit`); startup time measured before/after (target: no regression from ~50ms baseline).

## PR 2 — CI / template cleanup (`refactor/ci-templates`)

1. Merge the near-identical `chezmoi-linux` / `chezmoi-macos` jobs in `.github/workflows/test.yml` into one matrix job; only the runner and the chezmoi install step differ (parameterize via matrix keys). ~80 lines removed.
2. Replace `env "…" | not | not` with `ne (env "…") ""` and `lookPath "op" | not | not` with `ne (lookPath "op") ""` in `.chezmoi.yaml.tmpl` (boolean semantics identical for string/nil inputs).
3. Unify the template-stripping sed pattern between `justfile` and CI to one spelling: `sed 's/{{[^}]*}}//g'`.

Verification: `just test`; `chezmoi execute-template` on touched templates; `BUSINESS_USE=1 chezmoi init --source=. --dry-run` and personal-mode dry-run; CI green on the PR (both matrix legs).

## PR 3 — hook sync + test coverage (`refactor/hook-tests`)

1. Add cross-reference comments tying the destructive-command guards together: a note in the deny block of `dot_claude/settings.json.tmpl` and a matching comment in `dot_codex/rules/custom.rules.tmpl` ("keep in sync with …").
2. Extend `tests/hooks/block-rot-comments.test.sh` with missing cases the hook already implements but tests don't cover: MultiEdit payloads (clean + rot), block-comment rot, `TEMP`/`HACK`/`XXX` markers. The hook handles all of these (`executable_block-rot-comments.py:64,103`), so new tests are expected to pass; any failure is a real bug to report, not silently fix.

Verification: run the hook test suite; all cases green with output shown.

## PR 4 — nvim lsp.lua table-driven servers (`refactor/nvim-lsp`)

Collapse the 16 repetitive `vim.lsp.config.<server> = { capabilities = … }` blocks in `dot_config/nvim/lua/plugins/lsp.lua` into a `servers` table plus a single loop that injects shared `capabilities`. Servers with custom settings keep their settings in the table; genuinely special cases (custom `cmd`) stay explicit outside the loop.

Verification: `just test` (includes nvim startup test); local headless boot mirroring CI (`nvim --headless "+Lazy! home" +qa` or the CI equivalent); confirm LSP configs resolve (`nvim --headless` + `vim.lsp.config` inspection).

## PR 5 — skills/rules light cleanup (`refactor/claude-rules`)

1. Delete `dot_claude/rules/browser-automation.md`; grep the repo for references to it and remove/adjust any.
2. Rename the two identical `### Structure Template` headings in `dot_claude/skills/x-post-craft/SKILL.md` (single post vs thread) so they are distinguishable.

Verification: `just test`; grep confirms no dangling references.

## Execution Model

- One implementation subagent per PR, `isolation: "worktree"`, briefed with the relevant repo rules inline (no conversation history).
- Main session reviews each diff directly (no separate review subagents — token economy per user instruction), classifying findings CRITICAL/IMPORTANT only.
- Maximum 5 review-fix iterations per PR; A→B→A reverts escalate to the user.
- Branches cut from `main`; PRs are independent and mergeable in any order. File overlap between PRs is zero by construction.

## Done Criteria (sprint contract)

- `just test` passes on every branch (output shown, exit code 0)
- Both chezmoi modes dry-run cleanly where templates changed (PR 1, 2, 3, 5)
- zsh startup time not regressed (PR 1, measured)
- Hook test suite passes with new cases (PR 3)
- nvim starts headless without errors (PR 4)
- No functional/behavioral change anywhere except documented performance fixes (duplicate compinit guard)
