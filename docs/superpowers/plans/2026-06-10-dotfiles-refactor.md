# Dotfiles Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Five independent, behavior-preserving refactoring PRs improving readability, maintainability, and performance per `docs/superpowers/specs/2026-06-10-dotfiles-refactor-design.md`.

**Architecture:** Each task below is one PR on its own branch cut from `main`. Tasks touch disjoint files and are mergeable in any order. Implementation is dispatched to worktree-isolated subagents; the main session reviews diffs.

**Tech Stack:** chezmoi Go templates, zsh, GitHub Actions, just, Lua (lazy.nvim), bash test harness.

**Conventions for every task:**

- Commit messages: conventional commits (`refactor(...): ...`), body ends with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Never run `chezmoi apply`. Dry-run only.
- Verification output must be shown in full with exit codes; "should pass" is forbidden.

---

### Task 1: zsh cleanup (branch `refactor/zsh-cleanup`)

**Files:**

- Modify: `dot_config/zsh/init/xdg.zsh` (add `ZSH_INIT_CACHE`)
- Modify: `dot_config/zsh/init/homebrew.zsh.tmpl:12`, `dot_config/zsh/init/mise.zsh:10`, `dot_config/zsh/init/plugins.zsh:90,96,109,122,157`, `dot_config/zsh/features/cache-mgmt.zsh:3,14`
- Modify: `dot_config/zsh/init/plugins.zsh` (header line), `dot_config/zsh/modules/bun.zsh:11`
- Modify: 8 feature files (headers): `dot_config/zsh/features/{branch-cleanup,cache-mgmt,devbox-brew,documentation,dotfiles-helpers,kube,local-config-cmd,profiling}.zsh`
- Modify: `justfile` (`lint-headers` recipe)
- Add (docs ride-along): `docs/superpowers/specs/2026-06-10-dotfiles-refactor-design.md`, `docs/superpowers/plans/2026-06-10-dotfiles-refactor.md`

- [ ] **Step 1 (Red): extend `lint-headers` to features/**

In `justfile`, change the loop glob in `lint-headers`:

```make
# Lint Provides header on zsh files (init/, modules/, features/)
lint-headers:
    @echo "Checking header convention..."
    @for f in dot_config/zsh/init/*.zsh* dot_config/zsh/modules/*.zsh* dot_config/zsh/features/*.zsh; do \
        if ! head -10 "$f" | grep -qE '^# Provides:'; then \
            echo "✗ $f: missing '# Provides:' header (top 10 lines)"; \
            exit 1; \
        fi \
    done
    @echo "✓ Headers OK!"
```

- [ ] **Step 2: run `just lint-headers`, confirm it FAILS** listing the 8 files above (Red).

- [ ] **Step 3 (Green): add headers to the 8 feature files**

Read each file first; the header must reflect its actual contents. Format (matches `features/git-branch-fzf.zsh`; `Side-effects:`/`Load-order:` lines only where the file has side effects beyond defining functions):

```zsh
# <name>.zsh - <one-line purpose>
# Provides:     <function names, variables — comma separated>
# Requires:     <external commands / files; omit if none>
```

Two worked examples:

```zsh
# branch-cleanup.zsh - remove local git branches already merged/squashed
# Provides:     rub, PROTECTED_BRANCHES
# Requires:     git
# Side-effects: defines PROTECTED_BRANCHES global
```

```zsh
# cache-mgmt.zsh - clear and rebuild zsh init caches
# Provides:     <actual function names from the file>
# Requires:     <actual deps>
```

Derive `Provides:` from the real function/variable names in each file — do not guess.

- [ ] **Step 4: run `just lint-headers`, confirm PASS** (Green).

- [ ] **Step 5: fix `init/plugins.zsh` Load-order header**

Replace the `# Load-order:` line (around line 8) with:

```zsh
# Load-order:   AFTER perf-flags; provides zinit consumed by options.zsh and features/
```

- [ ] **Step 6: centralize the init-cache path**

In `dot_config/zsh/init/xdg.zsh` (after the XDG exports):

```zsh
export ZSH_INIT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init"
```

Replace the 9 hardcoded occurrences:

- `init/homebrew.zsh.tmpl:12`: `_brew_cache="$ZSH_INIT_CACHE/brew.zsh"`
- `init/mise.zsh:10`: `_mise_cache="$ZSH_INIT_CACHE/mise.zsh"`
- `init/plugins.zsh:90`: `_zsh_cache="$ZSH_INIT_CACHE"`
- `init/plugins.zsh:96,109,122,157`: `local _<tool>_cache="$ZSH_INIT_CACHE/<tool>.zsh"`
- `features/cache-mgmt.zsh:3,14`: `rm -rf "$ZSH_INIT_CACHE"`

Confirm `xdg.zsh` loads before all consumers in `dot_zshrc.tmpl` include order (it is the first init file). Do NOT change `justfile:106` (`just clean`) — it runs outside a zsh login context.

- [ ] **Step 7: guard duplicate compinit in `modules/bun.zsh`**

Replace line 11 (`autoload -Uz compinit && compinit -C -d ...`) with:

```zsh
  (( $+functions[compdef] )) || { autoload -Uz compinit && compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump" }
```

Keep the existing explanatory comment; the `-d` dump path must stay identical.

- [ ] **Step 8: verify**

```bash
just test                                    # expect exit 0
for f in $(git diff --name-only -- '*.zsh'); do zsh -n "$f" && echo "✓ $f"; done
chezmoi execute-template < dot_config/zsh/init/homebrew.zsh.tmpl | zsh -n /dev/stdin
for i in 1 2 3; do /usr/bin/time zsh -i -c exit; done   # compare against main baseline; no regression
```

Measure the same `zsh -i -c exit` timing on `main` first for the baseline.

- [ ] **Step 9: commit** (split: docs commit + header/lint commit + cache-var commit + compinit commit, each ≤200 LOC)

---

### Task 2: CI / template cleanup (branch `refactor/ci-templates`)

**Files:**

- Modify: `.github/workflows/test.yml:132-216`
- Modify: `.chezmoi.yaml.tmpl:6-7`
- Modify: `justfile:29`

- [ ] **Step 1: merge chezmoi-linux/chezmoi-macos into one matrix job**

Replace both jobs (lines 132–216) with a single job. The curl installer works on both OSes; install to `$HOME/.local/bin` to avoid sudo:

```yaml
chezmoi:
  name: Chezmoi (${{ matrix.os }}, ${{ matrix.env_name }})
  needs: changes
  if: needs.changes.outputs.chezmoi == 'true'
  runs-on: ${{ matrix.os }}
  strategy:
    matrix:
      os: [ubuntu-latest, macos-latest]
      include:
        - business_use: ""
          env_name: personal
        - business_use: "1"
          env_name: business
  steps:
    - uses: actions/checkout@v4

    - name: Install chezmoi
      run: |
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        echo "$HOME/.local/bin" >> "$GITHUB_PATH"

    - name: Setup test config (provide prompted values)
      run: |
        mkdir -p ~/.config/chezmoi
        cat > ~/.config/chezmoi/chezmoi.yaml << 'EOF'
        data:
          name: "Test User"
          email: "test@example.com"
          work_email: "test@work.example.com"
        EOF

    - name: Test chezmoi init (dry-run)
      env:
        BUSINESS_USE: ${{ matrix.business_use }}
      run: |
        echo "Testing chezmoi template expansion..."
        chezmoi init --source="${PWD}" --dry-run --verbose

    - name: Verify template expansion
      env:
        BUSINESS_USE: ${{ matrix.business_use }}
      run: |
        chezmoi init --source="${PWD}"
        chezmoi managed | head -20
        chezmoi cat ~/.config/git/config || true
```

CAUTION — matrix semantics: `os: [...]` × `include: [...]` must expand to 4 jobs (2 os × 2 env). With a bare `include` alongside an `os` axis, GitHub _adds_ keys to existing combinations only if they don't conflict; the safe form is two axes:

```yaml
matrix:
  os: [ubuntu-latest, macos-latest]
  env_name: [personal, business]
  include:
    - env_name: personal
      business_use: ""
    - env_name: business
      business_use: "1"
```

Use this two-axis form. Search the rest of test.yml for references to job ids `chezmoi-linux` / `chezmoi-macos` (e.g. in a final `needs:` aggregation job) and update them to `chezmoi`.

- [ ] **Step 2: verify workflow syntax**

```bash
actionlint .github/workflows/test.yml 2>/dev/null || python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/test.yml'))"
```

Expected: no errors (use whichever tool is available; `devbox run -- actionlint` if installed).

- [ ] **Step 3: replace `| not | not` in `.chezmoi.yaml.tmpl`**

```go
{{- $businessUse := ne (env "BUSINESS_USE") "" -}}
{{- $hasOp := ne (lookPath "op") "" -}}
```

Semantics: `env` returns `""` when unset, `lookPath` returns `""` when missing — `ne x ""` is exactly `not (not x)` for these inputs.

- [ ] **Step 4: unify justfile sed pattern**

`justfile:29`: change `sed 's/\{\{[^}]*\}\}//g'` to `sed 's/{{[^}]*}}//g'` (matches CI spelling; braces need no escaping in a sed `s///` pattern).

- [ ] **Step 5: verify**

```bash
just test
chezmoi execute-template < dot_npmrc.tmpl >/dev/null && echo OK   # any template exercises .chezmoi.yaml.tmpl data
chezmoi init --source="$PWD" --dry-run >/dev/null && echo personal-OK
BUSINESS_USE=1 chezmoi init --source="$PWD" --dry-run >/dev/null && echo business-OK
```

All four must succeed. Note: `chezmoi init --dry-run` without apply does not touch the home dir.

- [ ] **Step 6: commit** (two commits: `ci:` matrix merge; `refactor(chezmoi):` template idiom + sed)

---

### Task 3: hook sync + test coverage (branch `refactor/hook-tests`)

**Files:**

- Modify: `dot_claude/settings.json.tmpl` (deny block), `dot_codex/rules/custom.rules.tmpl` (top comment)
- Modify: `tests/hooks/block-rot-comments.test.sh`

- [ ] **Step 1: add cross-reference markers**

JSON has no comments; `settings.json.tmpl` deny entries are strings. Add the note as a template comment so it never reaches rendered JSON — at the top of the deny block in the `.tmpl`:

```
{{- /* Destructive-command guards below overlap with dot_codex/rules/custom.rules.tmpl — when adding a pattern, update both. */ -}}
```

In `dot_codex/rules/custom.rules.tmpl`, add near the top:

```
# NOTE: destructive-command guards overlap with dot_claude/settings.json.tmpl
# ("deny" list) — when adding a pattern, update both files.
```

- [ ] **Step 2: read the existing test file and hook**, mirror its helper conventions (`run`, `is_block`, `fail`). New cases to append:

```bash
# === MultiEdit: clean edits pass ===
out=$(run '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.ts","edits":[{"old_string":"x=1","new_string":"x=2"}]}}')
is_allow "$out" || fail "clean MultiEdit was blocked: $out"

# === MultiEdit: rot comment in second edit blocks ===
out=$(run '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.ts","edits":[{"old_string":"x=1","new_string":"x=2"},{"old_string":"y=1","new_string":"// TODO: fix later\ny=2"}]}}')
is_block "$out" || fail "MultiEdit rot comment not blocked: $out"

# === HACK/TEMP/XXX markers block ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"// HACK: workaround\nf()"}}')
is_block "$out" || fail "HACK marker not blocked: $out"

# === block-comment style rot ===
out=$(run '{"tool_name":"Write","tool_input":{"file_path":"a.ts","content":"/* TEMP: remove after launch */\nf()"}}')
is_block "$out" || fail "block-comment TEMP not blocked: $out"
```

Adjust payload shape to the hook's actual `added_lines()` contract (`executable_block-rot-comments.py:96-110`) and the test file's actual helper names before writing — do not invent helpers. Markers regex is at hook line 63-66.

- [ ] **Step 3: run the suite**

```bash
bash tests/hooks/run-tests.sh
```

Expected: all pass. The hook already implements MultiEdit and markers; if any new case FAILS, STOP and report the failure verbatim — it is a real bug, do not patch the hook or weaken the test.

- [ ] **Step 4: verify templates still render**

```bash
chezmoi execute-template < dot_claude/settings.json.tmpl | python3 -c "import json,sys; json.load(sys.stdin)" && echo JSON-OK
BUSINESS_USE=1 chezmoi init --source="$PWD" --dry-run >/dev/null && echo business-OK
```

- [ ] **Step 5: commit** (two commits: `docs(guards):` cross-refs; `test(hooks):` coverage)

---

### Task 4: nvim lsp.lua table-driven servers (branch `refactor/nvim-lsp`)

**Files:**

- Modify: `dot_config/nvim/lua/plugins/lsp.lua:69-203`

- [ ] **Step 1: replace the 16 `vim.lsp.config.X = ...` blocks and the `vim.lsp.enable` list**

Keep lines 1–67 (mason setup, LspAttach autocmd, capabilities) unchanged. Replace lines 69–203 with:

```lua
      -- Server configs; capabilities are injected for all entries below.
      local servers = {
        bashls = { filetypes = { "sh", "bash", "zsh" } },
        cssls = {},
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        html = {},
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
              },
              diagnostics = { globals = { "vim" } },
              completion = { callSnippet = "Replace" },
            },
          },
        },
        -- MoonBit (not managed by mason, uses system `moon lsp`)
        moonbit_lsp = {
          cmd = { "moon", "lsp" },
          filetypes = { "moonbit" },
          root_markers = { "moon.mod.json" },
        },
        pyright = {},
        ruby_lsp = {},
        rust_analyzer = {},
        sorbet = {},
        taplo = {},
        terraformls = {},
        ts_ls = {},
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
      }

      for name, config in pairs(servers) do
        config.capabilities = capabilities
        vim.lsp.config[name] = config
      end

      vim.lsp.enable(vim.tbl_keys(servers))
```

Every server and every settings table above must match the original exactly — diff the rendered `vim.lsp.config` values if unsure. `mason-lspconfig.ensure_installed` (lines 26-41) stays as is (it intentionally excludes moonbit_lsp).

- [ ] **Step 2: format + verify**

```bash
stylua dot_config/nvim/ && just test
nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa!') end, 2000)" 2>&1 | tail -5
```

Expected: `just test` exits 0; headless boot exits clean with no Lua errors mentioning lsp.lua. Mirror the startup check CI uses in `.github/workflows/test.yml` (nvim job) if it differs.

- [ ] **Step 3: commit** (`refactor(nvim): table-drive LSP server configs`)

---

### Task 5: skills/rules light cleanup (branch `refactor/claude-rules`)

**Files:**

- Delete: `dot_claude/rules/browser-automation.md`
- Modify: `dot_claude/skills/x-post-craft/SKILL.md:102,144` (headings)

- [ ] **Step 1: check references, then delete the rule**

```bash
grep -rn "browser-automation" --include="*.md" --include="*.json*" --include="*.sh" . | grep -v ".git/"
```

Remove/adjust any hits (e.g. an index in `dot_claude/CLAUDE.md` or a hookify/rules-inject reference), then `git rm dot_claude/rules/browser-automation.md`.

- [ ] **Step 2: disambiguate x-post-craft headings**

Rename the `### Structure Template` under `## Generation Rules` (line ~102) to `### Structure Template (Single Post)` and the one under `## Thread Design` (line ~144) to `### Structure Template (Thread)`.

- [ ] **Step 3: verify**

```bash
just test
grep -rn "browser-automation" . --include="*" 2>/dev/null | grep -v ".git/" || echo "no dangling refs"
```

- [ ] **Step 4: commit** (`refactor(claude): drop duplicate browser rule, disambiguate x-post-craft headings`)

---

## Review protocol (main session)

For each completed task: review the diff directly (no review subagents), check against the spec section, classify findings CRITICAL/IMPORTANT only, max 5 fix iterations, escalate A→B→A reverts. Push + PR creation only after user confirmation.
