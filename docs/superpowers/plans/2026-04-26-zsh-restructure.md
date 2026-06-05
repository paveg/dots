# Zsh 設定再整理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `dot_zshrc.tmpl` (250 行) と `functions.zsh` (667 行) を責務単位に分解し、副作用が読めるヘッダ規約を導入する。worktree 機能は廃止。

**Architecture:** `dot_config/zsh/` を `init/` (順序クリティカル) / `modules/` (環境セットアップ) / `features/` (純粋関数) の 3 層に分割。`dot_zshrc.tmpl` は `{{ include }}` を順番に列挙する ~70 行のオーケストレータに縮小。副作用あるファイルは `# Provides:` ヘッダで依存・副作用を宣言。

**Tech Stack:** chezmoi (Go template), zsh, zinit, just (taskrunner), bash (CI lint)

**Spec:** `docs/superpowers/specs/2026-04-26-zsh-restructure-design.md`

**TDD note:** This is a dotfiles refactor. Per user rules (`~/.claude/rules/tdd.md`), TDD's Red-Green-Refactor cycle does not apply. Verification is via baseline capture + post-change diff comparison.

**chezmoi apply policy:** Per user hook, every `chezmoi apply` requires explicit user confirmation. Use `chezmoi apply --dry-run --verbose` for verification; ask the user before any real apply.

---

## File Structure

### Created (new files)

| Path | Lines (est.) | Header |
|------|-------------|--------|
| `dot_config/zsh/init/xdg.zsh` | ~6 | required |
| `dot_config/zsh/init/homebrew.zsh.tmpl` | ~18 | required |
| `dot_config/zsh/init/terminal.zsh` | ~12 | required |
| `dot_config/zsh/init/perf-flags.zsh` | ~5 | required |
| `dot_config/zsh/init/mise.zsh` | ~13 | required |
| `dot_config/zsh/init/auto-tmux.zsh.tmpl` | ~50 | required |
| `dot_config/zsh/init/p10k-instant.zsh` | ~6 | required |
| `dot_config/zsh/modules/ssh-agent.zsh.tmpl` | ~32 | required |
| `dot_config/zsh/modules/bun.zsh` | ~9 | required |
| `dot_config/zsh/modules/pnpm.zsh` | ~8 | required |
| `dot_config/zsh/modules/vite-plus.zsh` | ~5 | required |
| `dot_config/zsh/modules/cf-cli.zsh` | ~5 | required |
| `dot_config/zsh/modules/telemetry.zsh.tmpl` | ~22 | required |
| `dot_config/zsh/modules/local-config.zsh` | ~10 | required |
| `dot_config/zsh/modules/p10k-config.zsh` | ~6 | required |
| `dot_config/zsh/features/ghq-fzf.zsh` | ~80 | required |
| `dot_config/zsh/features/branch-cleanup.zsh` | ~16 | optional |
| `dot_config/zsh/features/kube.zsh` | ~50 | optional |
| `dot_config/zsh/features/rgn.zsh` | ~50 | required |
| `dot_config/zsh/features/devbox-brew.zsh` | ~30 | optional |
| `dot_config/zsh/features/profiling.zsh` | ~5 | optional |
| `dot_config/zsh/features/dotenv-auto.zsh` | ~30 | required |
| `dot_config/zsh/features/cache-mgmt.zsh` | ~25 | optional |
| `dot_config/zsh/features/dotfiles-helpers.zsh` | ~80 | optional |
| `dot_config/zsh/features/local-config-cmd.zsh` | ~70 | optional |
| `dot_config/zsh/features/documentation.zsh` | ~13 | optional |

### Renamed/moved (content unchanged or minor)

| From | To |
|------|-----|
| `dot_config/zsh/split/options.zsh` | `dot_config/zsh/init/options.zsh` |
| `dot_config/zsh/split/plugins.zsh` | `dot_config/zsh/init/plugins.zsh` |
| `dot_config/zsh/split/aliases.zsh` | `dot_config/zsh/aliases.zsh` |
| `dot_config/zsh/split/atcoder.zsh` | `dot_config/zsh/atcoder.zsh` |

### Deleted

| Path | Reason |
|------|--------|
| `dot_config/zsh/split/` (全体) | 責務分散後は不要 |
| `dot_config/zsh/split/wt-interactive.zsh` | worktree 機能廃止 |
| `dot_config/zsh/split/functions.zsh` | features/ に分解後 |

### Modified

| Path | 変更概要 |
|------|----------|
| `dot_zshrc.tmpl` | 250 → ~70 行のオーケストレータに縮小 |
| `dot_tmux.conf` | line 105 の `bind g` 削除 |
| `.chezmoiignore` | `split/atcoder.zsh` → `atcoder.zsh` パス更新 |
| `justfile` | `lint-headers` ターゲット追加、`test` から呼ぶ |

---

## Task 0: ベースライン取得

**Why:** 変更前の zsh 状態をスナップショット化。後続タスク完了時に「期待外の差分」がないことを差分比較で検証する。

**Files:**
- Create: `/tmp/zsh-baseline-functions.txt`
- Create: `/tmp/zsh-baseline-env.txt`
- Create: `/tmp/zsh-baseline-aliases.txt`
- Create: `/tmp/zsh-baseline-zshtime.txt`

- [ ] **Step 0.1: 関数一覧をベースラインとして記録**

```bash
zsh -i -c 'print -l ${(k)functions} | sort' > /tmp/zsh-baseline-functions.txt
wc -l /tmp/zsh-baseline-functions.txt
```

Expected: 数百行程度の関数一覧が出力される。

- [ ] **Step 0.2: alias 一覧を記録**

```bash
zsh -i -c 'print -l ${(k)aliases} | sort' > /tmp/zsh-baseline-aliases.txt
wc -l /tmp/zsh-baseline-aliases.txt
```

- [ ] **Step 0.3: 環境変数一覧を記録 (機密情報を除外)**

```bash
zsh -i -c 'env | grep -E "^(XDG_|HOMEBREW_|PNPM_HOME|MISE_|TERM)" | sort' > /tmp/zsh-baseline-env.txt
cat /tmp/zsh-baseline-env.txt
```

Expected: XDG_*, HOMEBREW_*, PNPM_HOME, TERM などが列挙される。

- [ ] **Step 0.4: 起動時間ベースラインを記録**

```bash
{ for i in {1..10}; do (time zsh -i -c exit) 2>&1; done; } > /tmp/zsh-baseline-zshtime.txt
cat /tmp/zsh-baseline-zshtime.txt
```

Expected: 各行に `zsh -i -c exit  0.04s user ...` 形式のタイムが出る。中央値が大体 50ms 前後。

---

## Task 1: worktree 機能の廃止

**Files:**
- Modify: `dot_config/zsh/split/functions.zsh` (worktree 関連 12 関数を削除)
- Delete: `dot_config/zsh/split/wt-interactive.zsh`
- Modify: `dot_tmux.conf` (line 105 の `bind g` 削除)

- [ ] **Step 1.1: functions.zsh から worktree 関連を削除**

`dot_config/zsh/split/functions.zsh` を開き、以下の関数定義を削除:

- `_wt_repo_basename()` (455 付近)
- `_wt_dir()` (459)
- `_wt_guard()` (466)
- `_wt_add()` (477)
- `_wt_fzf_select()` (503)
- `_wt_rm()` (517)
- `_wt_ls()` (545)
- `_wt_cd()` (581)
- `_wt_list_names()` (596)
- `_wt_interactive()` (623)
- `_wt_usage()` (642)
- `wt()` (657)

セクションヘッダ (`# === worktree ...`) があれば一緒に削除。grep で確認:

```bash
grep -nE '_wt_|^wt\(\)|^wt ' dot_config/zsh/split/functions.zsh
```

Expected (削除後): 空（マッチなし）。

- [ ] **Step 1.2: wt-interactive.zsh を削除**

```bash
rm dot_config/zsh/split/wt-interactive.zsh
ls dot_config/zsh/split/
```

Expected: `aliases.zsh atcoder.zsh functions.zsh options.zsh plugins.zsh` のみ表示。

- [ ] **Step 1.3: dot_tmux.conf の bind g を削除**

`dot_tmux.conf` の line 105 周辺:

```
# Opens a menu for worktree operations via display-popup
bind g run-shell 'tmux display-popup -E -w 80% -h 60% "zsh ~/.config/zsh/split/wt-interactive.zsh #{pane_current_path}"'
```

これを 2 行とも削除（前のコメント行も）。

確認:

```bash
grep -n 'wt-interactive\|wt_interactive\|bind g ' dot_tmux.conf
```

Expected: マッチなし。

- [ ] **Step 1.4: 構文チェック**

```bash
just lint
```

Expected: `✓ dot_zshrc.tmpl ✓ dot_zshenv.tmpl ✓ Done!` と表示。

- [ ] **Step 1.5: chezmoi diff で意図した削除のみであること確認**

```bash
chezmoi diff
```

Expected: `~/.config/zsh/split/functions.zsh` から worktree 関連が削除、`~/.config/zsh/split/wt-interactive.zsh` が削除、`~/.tmux.conf` から bind g が削除されている。それ以外の差分はない。

- [ ] **Step 1.6: ユーザーに chezmoi apply の確認を依頼**

ユーザーに以下を提示して許可を得る:

> 「Step 1 の差分を確認しました。`chezmoi apply` を実行しますか？」

許可を得てから実行:

```bash
chezmoi apply
```

- [ ] **Step 1.7: 起動確認**

```bash
zsh -i -c 'type wt 2>&1; type _wt_dir 2>&1' | grep -E 'not found|not a function'
```

Expected: 両方とも `not found` または `not a function` と表示される。

- [ ] **Step 1.8: コミット**

```bash
git add dot_config/zsh/split/functions.zsh dot_tmux.conf
git rm dot_config/zsh/split/wt-interactive.zsh
git commit -m "$(cat <<'EOF'
feat(zsh): remove worktree feature

The wt() command family and tmux popup launcher are no longer needed.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: split/ ファイルを上位ディレクトリへ promote

**Why:** 後続タスクで init/, modules/, features/ を作る前に、既存の split/options.zsh / plugins.zsh / aliases.zsh / atcoder.zsh を最終配置に移しておくことで、dot_zshrc.tmpl の include パス書き換えが 1 回で済む。

**Files:**
- Move: `dot_config/zsh/split/options.zsh` → `dot_config/zsh/init/options.zsh`
- Move: `dot_config/zsh/split/plugins.zsh` → `dot_config/zsh/init/plugins.zsh`
- Move: `dot_config/zsh/split/aliases.zsh` → `dot_config/zsh/aliases.zsh`
- Move: `dot_config/zsh/split/atcoder.zsh` → `dot_config/zsh/atcoder.zsh`
- Modify: `dot_zshrc.tmpl` (include パス更新)
- Modify: `.chezmoiignore` (split/atcoder.zsh → atcoder.zsh)

- [ ] **Step 2.1: init/ ディレクトリ作成 + options.zsh / plugins.zsh 移動**

```bash
mkdir -p dot_config/zsh/init
git mv dot_config/zsh/split/options.zsh dot_config/zsh/init/options.zsh
git mv dot_config/zsh/split/plugins.zsh dot_config/zsh/init/plugins.zsh
ls dot_config/zsh/init/
```

Expected: `options.zsh plugins.zsh` が表示。

- [ ] **Step 2.2: aliases.zsh / atcoder.zsh を top-level へ移動**

```bash
git mv dot_config/zsh/split/aliases.zsh dot_config/zsh/aliases.zsh
git mv dot_config/zsh/split/atcoder.zsh dot_config/zsh/atcoder.zsh
ls dot_config/zsh/split/
```

Expected: `functions.zsh` のみ残る。

- [ ] **Step 2.3: dot_zshrc.tmpl の include パスを更新**

`dot_zshrc.tmpl` の以下を編集:

Before (line 131-137):
```
{{ include "dot_config/zsh/split/plugins.zsh" }}
{{ include "dot_config/zsh/split/options.zsh" }}
{{ include "dot_config/zsh/split/aliases.zsh" }}
{{ include "dot_config/zsh/split/functions.zsh" }}
{{- if not .business_use }}
{{ include "dot_config/zsh/split/atcoder.zsh" }}
{{- end }}
```

After:
```
{{ include "dot_config/zsh/init/plugins.zsh" }}
{{ include "dot_config/zsh/init/options.zsh" }}
{{ include "dot_config/zsh/aliases.zsh" }}
{{ include "dot_config/zsh/split/functions.zsh" }}
{{- if not .business_use }}
{{ include "dot_config/zsh/atcoder.zsh" }}
{{- end }}
```

(`functions.zsh` は次タスクで分解するのでまだ split/ パスのまま)

確認:
```bash
grep -nE 'split/(options|plugins|aliases|atcoder)' dot_zshrc.tmpl
```

Expected: マッチなし。

- [ ] **Step 2.4: .chezmoiignore のパス更新**

`.chezmoiignore` の line 49:

Before:
```
.config/zsh/split/atcoder.zsh
```

After:
```
.config/zsh/atcoder.zsh
```

確認:
```bash
grep -nE 'zsh/(split/)?atcoder' .chezmoiignore
```

Expected: 1 行だけマッチ、パスが `.config/zsh/atcoder.zsh` になっている。

- [ ] **Step 2.5: 構文チェック + chezmoi diff**

```bash
just lint && chezmoi diff
```

Expected:
- lint 成功
- chezmoi diff は **ファイル移動の差分のみ** (`~/.config/zsh/split/{options,plugins,aliases,atcoder}.zsh` の削除と `~/.config/zsh/init/{options,plugins}.zsh` `~/.config/zsh/{aliases,atcoder}.zsh` の作成)
- **`~/.zshrc` の生成内容は変わらないこと** を確認（`chezmoi diff ~/.zshrc` で確認可能、または diff 全体に `~/.zshrc` の差分が含まれていないこと）

それ以外の予期せぬ差分が出た場合: include の順序や条件分岐がずれている可能性。再確認すること。

- [ ] **Step 2.6: ユーザーに chezmoi apply 許可を依頼 + 実行**

> 「Step 2 の差分を確認しました。chezmoi apply を実行しますか？」

```bash
chezmoi apply
zsh -i -c exit && echo "✓ shell starts"
```

Expected: エラーなく終了。

- [ ] **Step 2.7: 関数到達性確認**

```bash
zsh -i -c 'type repos rub kctx atcoder-login 2>&1' | grep -v 'not found'
```

Expected: 各関数が定義されていることを示す出力。`not found` の行がゼロ。

- [ ] **Step 2.8: コミット**

```bash
git add dot_zshrc.tmpl .chezmoiignore
git commit -m "$(cat <<'EOF'
refactor(zsh): promote split/ files to top-level zsh dir

Move options.zsh and plugins.zsh into init/, and aliases.zsh /
atcoder.zsh to the top of dot_config/zsh/. Prepares for the upcoming
init/modules/features split.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: dot_zshrc.tmpl から init/ セクションを抽出

**Why:** 起動シーケンス（順序クリティカル）の各セクションを `init/` 配下の独立ファイルに切り出す。`{{ include }}` で同じ順番に並べることで、生成される `~/.zshrc` の内容は不変。

**Files:**
- Create: `dot_config/zsh/init/xdg.zsh`
- Create: `dot_config/zsh/init/homebrew.zsh.tmpl`
- Create: `dot_config/zsh/init/terminal.zsh`
- Create: `dot_config/zsh/init/perf-flags.zsh`
- Create: `dot_config/zsh/init/mise.zsh`
- Create: `dot_config/zsh/init/auto-tmux.zsh.tmpl`
- Create: `dot_config/zsh/init/p10k-instant.zsh`
- Modify: `dot_zshrc.tmpl` (該当セクションを `{{ include }}` に置換)

- [ ] **Step 3.1: xdg.zsh を作成**

`dot_config/zsh/init/xdg.zsh`:

```zsh
# XDG Base Directory (fallback if .zshenv not sourced)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
```

(ヘッダは Task 7 でまとめて追加)

- [ ] **Step 3.2: homebrew.zsh.tmpl を作成**

`dot_config/zsh/init/homebrew.zsh.tmpl`:

```zsh
# Homebrew setup (macOS)
{{- if eq .chezmoi.os "darwin" }}
# shellenv is cached; invalidated automatically when brew binary updates
_brew_bin="/opt/homebrew/bin/brew"
if [[ -x "$_brew_bin" ]]; then
  _brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/brew.zsh"
  if [[ ! -f "$_brew_cache" ]] || [[ "$_brew_bin" -nt "$_brew_cache" ]]; then
    mkdir -p "$(dirname "$_brew_cache")"
    "$_brew_bin" shellenv > "$_brew_cache"
  fi
  source "$_brew_cache"
fi
unset _brew_bin _brew_cache
{{- end }}

# Prevent accidental installation of tools managed by other package managers
# - node/npm/pnpm/yarn: use devbox or mise
# - python/pip: use uv
# - claude: use npm -g
export HOMEBREW_FORBIDDEN_FORMULAE="node python python3 pip npm pnpm yarn claude"
```

- [ ] **Step 3.3: terminal.zsh を作成**

`dot_config/zsh/init/terminal.zsh`:

```zsh
# Terminal compatibility
# Fall back to xterm-256color if terminfo is missing (e.g., SSH to older servers)
if [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty &>/dev/null; then
  export TERM=xterm-256color
fi

# Ensure TERM matches tmux default-terminal when inside tmux
if [[ -n "$TMUX" ]] && [[ "$TERM" != "screen-256color" ]]; then
  export TERM=screen-256color
fi
```

- [ ] **Step 3.4: perf-flags.zsh を作成**

`dot_config/zsh/init/perf-flags.zsh`:

```zsh
# Performance flags
DISABLE_MAGIC_FUNCTIONS=true
skip_global_compinit=1
```

- [ ] **Step 3.5: mise.zsh を作成**

`dot_config/zsh/init/mise.zsh`:

```zsh
# mise (runtime version manager) - early activation for tmux
# Must be activated before auto_tmux to ensure tmux is in PATH
if command -v mise &>/dev/null; then
  _mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/mise.zsh"
  # Invalidate cache when mise version changes
  _mise_ver="$(mise --version 2>/dev/null)"
  if [[ ! -f "$_mise_cache" ]] || ! grep -qF "# mise $_mise_ver" "$_mise_cache" 2>/dev/null; then
    mkdir -p "$(dirname "$_mise_cache")"
    { echo "# mise $_mise_ver"; mise activate zsh; } > "$_mise_cache"
  fi
  source "$_mise_cache"
  unset _mise_cache _mise_ver
fi
```

- [ ] **Step 3.6: auto-tmux.zsh.tmpl を作成**

`dot_config/zsh/init/auto-tmux.zsh.tmpl`:

```zsh
# Auto tmux on terminal startup
# Must run BEFORE p10k instant prompt (exec replaces shell, breaks p10k state)
auto_tmux() {
  # Skip if already in tmux
  [[ -n "$TMUX" ]] && return 0
  # Skip if not interactive
  [[ ! -o interactive ]] && return 0
  # Skip if explicitly disabled
  [[ "${DISABLE_AUTO_TMUX:-0}" = "1" ]] && return 0
  # Skip in CI/Docker
  [[ -n "$CI" || -n "$CONTAINER" || -f /.dockerenv ]] && return 0

  if (( $+commands[tmux] )); then
    # Get existing sessions
    local sessions
    sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})

    if (( ${#sessions[@]} == 0 )); then
      # No sessions: create new
      exec tmux new-session
    elif (( ${#sessions[@]} == 1 )); then
      # Single session: attach directly
      exec tmux attach-session -t "${sessions[1]}"
    else
      # Multiple sessions: select with fzf or fallback
      local selected
      if (( $+commands[fzf] )); then
        selected=$(tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_created_string})' 2>/dev/null \
          | fzf --height=40% --reverse --header="Select tmux session (ESC for new)" \
          | cut -d: -f1)
      else
        # Fallback: attach to first session if fzf unavailable
        selected="${sessions[1]}"
      fi

      if [[ -n "$selected" ]]; then
        exec tmux attach-session -t "$selected"
      else
        exec tmux new-session
      fi
    fi
  fi
}
auto_tmux
```

(注: 本ファイルは `dot_zshrc.tmpl` 側で `{{ if .auto_tmux }}` ガード内で include されるため、ファイル本体には条件分岐を持たない)

- [ ] **Step 3.7: p10k-instant.zsh を作成**

`dot_config/zsh/init/p10k-instant.zsh`:

```zsh
# Powerlevel10k instant prompt
# Enable instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

- [ ] **Step 3.8: dot_zshrc.tmpl の対応セクションを include に置換**

現在 `dot_zshrc.tmpl` の line 1〜130 にある以下のセクションを、対応する `{{ include }}` に置換:

- Lines 6-12 (XDG Base Directory) → `{{ include "dot_config/zsh/init/xdg.zsh" }}`
- Lines 14-35 (Homebrew setup + HOMEBREW_FORBIDDEN_FORMULAE) → `{{ include "dot_config/zsh/init/homebrew.zsh.tmpl" }}`
- Lines 37-48 (Terminal compatibility) → `{{ include "dot_config/zsh/init/terminal.zsh" }}`
- Lines 50-54 (Performance flags) → `{{ include "dot_config/zsh/init/perf-flags.zsh" }}`
- Lines 56-70 (mise activation) → `{{ include "dot_config/zsh/init/mise.zsh" }}`
- Lines 72-119 (auto_tmux block, 既に `{{ if .auto_tmux }}` でガードされている) → `{{- if .auto_tmux }}` `{{ include "dot_config/zsh/init/auto-tmux.zsh.tmpl" }}` `{{- end }}`
- Lines 121-129 (p10k instant prompt) → `{{ include "dot_config/zsh/init/p10k-instant.zsh" }}`

最初のセクション（profiling、line 1-4）は `dot_zshrc.tmpl` に残す。

確認:
```bash
grep -nE 'XDG_CONFIG_HOME=|brew shellenv|TERM=xterm-ghostty|DISABLE_MAGIC_FUNCTIONS|mise activate|auto_tmux\(\)|p10k-instant-prompt' dot_zshrc.tmpl
```

Expected: マッチなし（すべて include に外出し済み）。

- [ ] **Step 3.9: 構文チェック + chezmoi diff**

```bash
just lint && chezmoi diff
```

Expected:
- lint 成功
- chezmoi diff は **新規ファイル作成の差分のみ** (`~/.config/zsh/init/*.zsh` 群の追加)
- **`~/.zshrc` の生成内容は変わらないこと** を確認（diff に `~/.zshrc` 自体の差分が含まれていないこと）

- [ ] **Step 3.10: ユーザー確認 + chezmoi apply**

> 「Task 3 の差分は空なはずです。chezmoi apply を実行しますか？」

```bash
chezmoi apply
zsh -i -c exit && echo "✓ shell starts"
```

- [ ] **Step 3.11: コミット**

```bash
git add dot_config/zsh/init/ dot_zshrc.tmpl
git commit -m "$(cat <<'EOF'
refactor(zsh): extract init/ from dot_zshrc.tmpl

Split startup-order-critical sections into dot_config/zsh/init/:
xdg, homebrew, terminal, perf-flags, mise, auto-tmux, p10k-instant.
The generated ~/.zshrc is unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: dot_zshrc.tmpl から modules/ セクションを抽出

**Files:**
- Create: `dot_config/zsh/modules/ssh-agent.zsh.tmpl`
- Create: `dot_config/zsh/modules/bun.zsh`
- Create: `dot_config/zsh/modules/pnpm.zsh`
- Create: `dot_config/zsh/modules/vite-plus.zsh`
- Create: `dot_config/zsh/modules/cf-cli.zsh`
- Create: `dot_config/zsh/modules/telemetry.zsh.tmpl`
- Create: `dot_config/zsh/modules/local-config.zsh`
- Create: `dot_config/zsh/modules/p10k-config.zsh`
- Modify: `dot_zshrc.tmpl`

- [ ] **Step 4.1: ssh-agent.zsh.tmpl を作成**

`dot_config/zsh/modules/ssh-agent.zsh.tmpl`:

```zsh
# SSH Agent
{{- if eq .chezmoi.os "darwin" }}
# macOS: Use system SSH agent with Keychain integration
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  # Try to get from launchctl first
  local sock
  sock=$(launchctl getenv SSH_AUTH_SOCK)

  # Fallback: Find listener socket safely (restricted to current user)
  if [[ ! -S "$sock" ]]; then
    sock=$(find /private/tmp/com.apple.launchd.* -name Listeners -user "$USER" -type s 2>/dev/null | head -1)
  fi

  [[ -S "$sock" ]] && export SSH_AUTH_SOCK="$sock"
fi

# Load keys into agent (only if agent is available)
[[ -S "$SSH_AUTH_SOCK" ]] && ssh-add --apple-load-keychain &>/dev/null
{{- else }}
# Linux: Use keychain for SSH agent management
if command -v keychain &>/dev/null; then
  local ssh_keys=()
  [[ -f "$HOME/.ssh/id_ed25519" ]] && ssh_keys+=("id_ed25519")
  [[ -f "$HOME/.ssh/id_github" ]] && ssh_keys+=("id_github")
  [[ -f "$HOME/.ssh/id_rsa" ]] && ssh_keys+=("id_rsa")

  if (( ${#ssh_keys[@]} > 0 )); then
    eval "$(keychain --eval --quiet ${ssh_keys[@]})"
  fi
fi
{{- end }}
```

- [ ] **Step 4.2: bun.zsh を作成**

`dot_config/zsh/modules/bun.zsh`:

```zsh
# bun completions
# Pre-load compinit with -C so _bun's internal fallback (which calls plain
# `compinit`, triggering compaudit ~13ms) is skipped via its `command -v` guard.
if [[ -s "$HOME/.bun/_bun" ]]; then
  autoload -Uz compinit && compinit -C -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump"
  source "$HOME/.bun/_bun"
fi
```

- [ ] **Step 4.3: pnpm.zsh を作成**

`dot_config/zsh/modules/pnpm.zsh`:

```zsh
# pnpm setup
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
```

- [ ] **Step 4.4: vite-plus.zsh を作成**

`dot_config/zsh/modules/vite-plus.zsh`:

```zsh
# Vite+ bin
[[ -f "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
```

- [ ] **Step 4.5: cf-cli.zsh を作成**

`dot_config/zsh/modules/cf-cli.zsh`:

```zsh
# CF CLI completions (shipped via Vite+)
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"
```

- [ ] **Step 4.6: telemetry.zsh.tmpl を作成**

`dot_config/zsh/modules/telemetry.zsh.tmpl`:

```zsh
# Claude Code Telemetry → Grafana Cloud (personal only)
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_SERVICE_NAME="claude-code"
export OTEL_RESOURCE_ATTRIBUTES="service.namespace=LLMs"
export OTEL_METRICS_EXPORTER=otlp
export OTEL_TRACES_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-ap-northeast-0.grafana.net/otlp"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic $(printf '%s' '{{ .grafana_instance_id }}:{{ .grafana_api_token }}' | base64)"
# Trace/log detail flags
export OTEL_LOG_TOOL_CONTENT=true
export OTEL_LOG_TOOL_DETAILS=true
export OTEL_LOG_USER_PROMPTS=true
# Enable session/version dimensions for future metrics aggregation
export OTEL_METRICS_INCLUDE_SESSION_ID=true
export OTEL_METRICS_INCLUDE_VERSION=true
# Grafana SA token for dashboard provisioning (just grr-push)
export GRAFANA_SA_TOKEN="{{ .grafana_sa_token }}"
```

(注: ファイル内に `{{ if not .business_use }}` のガードを書かない。条件は dot_zshrc.tmpl 側の include 周辺でかける)

- [ ] **Step 4.7: local-config.zsh を作成**

`dot_config/zsh/modules/local-config.zsh`:

```zsh
# Local environment variables (not managed by chezmoi)
# Priority: .env.local -> .zshrc.local (both are gitignored)

# Machine-specific environment variables
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# Machine-specific shell configuration
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

- [ ] **Step 4.8: p10k-config.zsh を作成**

`dot_config/zsh/modules/p10k-config.zsh`:

```zsh
# Powerlevel10k configuration
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

- [ ] **Step 4.9: dot_zshrc.tmpl の対応セクションを include に置換**

現在 `dot_zshrc.tmpl` の以下のセクション (line 番号は Task 3 適用後でずれている、grep で位置確認):

- SSH Agent block → `{{ include "dot_config/zsh/modules/ssh-agent.zsh.tmpl" }}`
- bun completions block → `{{ include "dot_config/zsh/modules/bun.zsh" }}`
- pnpm setup block → `{{ include "dot_config/zsh/modules/pnpm.zsh" }}`
- Vite+ bin block → `{{ include "dot_config/zsh/modules/vite-plus.zsh" }}`
- CF CLI completions block → `{{ include "dot_config/zsh/modules/cf-cli.zsh" }}`
- Claude Code Telemetry block (現在 `{{ if not .business_use }}{{ if and ... }}` でガードされている) → 同じガード内で `{{ include "dot_config/zsh/modules/telemetry.zsh.tmpl" }}`
- Local environment variables block → `{{ include "dot_config/zsh/modules/local-config.zsh" }}`
- Powerlevel10k configuration block → `{{ include "dot_config/zsh/modules/p10k-config.zsh" }}`

確認:
```bash
grep -nE 'SSH_AUTH_SOCK|_bun|PNPM_HOME=|vite-plus/env|_cf.zsh|CLAUDE_CODE_ENABLE_TELEMETRY|env.local|p10k.zsh' dot_zshrc.tmpl
```

Expected: マッチなし。

- [ ] **Step 4.10: 構文チェック + chezmoi diff**

```bash
just lint && chezmoi diff
```

Expected:
- lint 成功
- chezmoi diff は **新規ファイル作成の差分のみ** (`~/.config/zsh/modules/*.zsh` 群の追加)
- **`~/.zshrc` の生成内容は変わらないこと** を確認

- [ ] **Step 4.11: ユーザー確認 + chezmoi apply**

```bash
chezmoi apply
zsh -i -c exit && echo "✓ shell starts"
zsh -i -c 'echo $XDG_CONFIG_HOME $HOMEBREW_PREFIX $PNPM_HOME'
```

Expected: 各環境変数が空でない。

- [ ] **Step 4.12: コミット**

```bash
git add dot_config/zsh/modules/ dot_zshrc.tmpl
git commit -m "$(cat <<'EOF'
refactor(zsh): extract modules/ from dot_zshrc.tmpl

Split environment-setup sections into dot_config/zsh/modules/:
ssh-agent, bun, pnpm, vite-plus, cf-cli, telemetry, local-config,
p10k-config. The generated ~/.zshrc is unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: functions.zsh を features/ に分解

**Why:** `functions.zsh` (現状 ~450 行、worktree 削除済み) を 11 ドメイン別ファイルに分割する。各ファイルは独立した機能カテゴリで、内部のグローバル変数共有はファイル内に閉じる。

**Files:**
- Create: 11 files under `dot_config/zsh/features/`
- Delete: `dot_config/zsh/split/functions.zsh`
- Delete: `dot_config/zsh/split/` (空になるため)
- Modify: `dot_zshrc.tmpl`

**重要**: 元の `functions.zsh` から該当する関数定義 + 関連変数 + コメントを丸ごと切り出すこと。**コードの中身は変えない**（これは pure refactor）。

- [ ] **Step 5.1: ghq-fzf.zsh を作成**

`dot_config/zsh/features/ghq-fzf.zsh` に、`functions.zsh` から以下を切り出して配置:

- セクションヘッダコメント（`# === Functions ===` のような汎用ヘッダではなく、関数固有のコメントのみ）
- `_GHQ_CACHE` 変数定義
- `_ghq_cache_update()`
- `_ghq_cache_update &!` バックグラウンド初期化ブロック (cache 不在時のみ)
- `ghq()` ラッパ関数
- `_fzf_cd_ghq()`
- `zle -N _fzf_cd_ghq` と `bindkey '^g' _fzf_cd_ghq`
- `alias repos='_fzf_cd_ghq'`

確認: ファイル内で `_GHQ_CACHE` が完結している (他ファイルから参照されない)。

```bash
grep -rn '_GHQ_CACHE' dot_config/zsh/ | grep -v features/ghq-fzf.zsh
```

Expected: マッチなし。

- [ ] **Step 5.2: branch-cleanup.zsh を作成**

`dot_config/zsh/features/branch-cleanup.zsh`:

`functions.zsh` から以下を切り出す:
- `PROTECTED_BRANCHES` 変数定義
- `rub()` 関数

確認:
```bash
grep -rn 'PROTECTED_BRANCHES\|rub()' dot_config/zsh/ | grep -v features/branch-cleanup.zsh
```

Expected: マッチなし。

- [ ] **Step 5.3: profiling.zsh を作成**

`dot_config/zsh/features/profiling.zsh`:

`functions.zsh` から:
- `zprofiler()` (1 行)
- `zshtime()` (1 行)

- [ ] **Step 5.4: local-config-cmd.zsh を作成**

`dot_config/zsh/features/local-config-cmd.zsh`:

`functions.zsh` から:
- `local-env()` 関数
- `local-zsh()` 関数

(注: ここでは「local config 管理コマンド」のみ。`source ~/.env.local` などの実際の読込みは `modules/local-config.zsh` で行う。命名で混同しないよう注意)

- [ ] **Step 5.5: documentation.zsh を作成**

`dot_config/zsh/features/documentation.zsh`:

`functions.zsh` から:
- `vdoc()` 関数

- [ ] **Step 5.6: dotfiles-helpers.zsh を作成**

`dot_config/zsh/features/dotfiles-helpers.zsh`:

`functions.zsh` から:
- `dots()` 関数 (chezmoi ヘルパ)

- [ ] **Step 5.7: cache-mgmt.zsh を作成**

`dot_config/zsh/features/cache-mgmt.zsh`:

`functions.zsh` から:
- `zsh-clear-cache()`
- `zsh-update-cache()`
- `zsh-bench()`

- [ ] **Step 5.8: dotenv-auto.zsh を作成**

`dot_config/zsh/features/dotenv-auto.zsh`:

`functions.zsh` から:
- `_auto_dotenv()` 関数
- `add-zsh-hook precmd _auto_dotenv` (関連 hook 登録があれば)

確認:
```bash
grep -n 'add-zsh-hook.*_auto_dotenv\|chpwd_functions.*_auto_dotenv' dot_config/zsh/features/dotenv-auto.zsh
```

Expected: マッチあり (hook 登録が含まれている)。

- [ ] **Step 5.9: kube.zsh を作成**

`dot_config/zsh/features/kube.zsh`:

`functions.zsh` から:
- `kctx()`
- `kns()`
- `kinfo()`

- [ ] **Step 5.10: rgn.zsh を作成**

`dot_config/zsh/features/rgn.zsh`:

`functions.zsh` から:
- `rgn()` 関数
- `_rgn_widget()` 関数
- `zle -N _rgn_widget` と関連 bindkey (元コードの最寄りの bindkey 行)

確認:
```bash
grep -n 'zle -N _rgn_widget\|bindkey.*_rgn' dot_config/zsh/features/rgn.zsh
```

Expected: 両方マッチ。

- [ ] **Step 5.11: devbox-brew.zsh を作成**

`dot_config/zsh/features/devbox-brew.zsh`:

`functions.zsh` から:
- `devbox()` ラッパ関数
- `brewbundle()` 関数

- [ ] **Step 5.12: 元の functions.zsh が空 / コメントだけになっていることを確認**

```bash
grep -vE '^\s*#|^\s*$' dot_config/zsh/split/functions.zsh
```

Expected: 空出力（コードがすべて移動済み）。残っている関数があれば該当する features/ に移す。

- [ ] **Step 5.13: split/ ディレクトリを削除**

```bash
git rm dot_config/zsh/split/functions.zsh
rmdir dot_config/zsh/split/
ls dot_config/zsh/split/ 2>&1
```

Expected: `No such file or directory` または該当ディレクトリなし。

- [ ] **Step 5.14: dot_zshrc.tmpl の include を更新**

`dot_zshrc.tmpl` 内の以下の行:

Before:
```
{{ include "dot_config/zsh/split/functions.zsh" }}
```

After (11 個の include に置換):
```
{{ include "dot_config/zsh/features/ghq-fzf.zsh" }}
{{ include "dot_config/zsh/features/branch-cleanup.zsh" }}
{{ include "dot_config/zsh/features/kube.zsh" }}
{{ include "dot_config/zsh/features/rgn.zsh" }}
{{ include "dot_config/zsh/features/devbox-brew.zsh" }}
{{ include "dot_config/zsh/features/profiling.zsh" }}
{{ include "dot_config/zsh/features/dotenv-auto.zsh" }}
{{ include "dot_config/zsh/features/cache-mgmt.zsh" }}
{{ include "dot_config/zsh/features/dotfiles-helpers.zsh" }}
{{ include "dot_config/zsh/features/local-config-cmd.zsh" }}
{{ include "dot_config/zsh/features/documentation.zsh" }}
```

確認:
```bash
grep -nE 'split/' dot_zshrc.tmpl
```

Expected: マッチなし。

- [ ] **Step 5.15: 構文チェック + chezmoi diff**

```bash
just lint && chezmoi diff
```

Expected:
- lint 成功
- chezmoi diff は **`~/.config/zsh/split/functions.zsh` の削除 + `~/.config/zsh/features/*.zsh` 群の追加** のみ
- **`~/.zshrc` の生成内容は変わらないこと** を確認

`~/.zshrc` に差分が出たら関数の切り出しでコードが欠落している可能性 — 該当箇所を再確認。

- [ ] **Step 5.16: ユーザー確認 + chezmoi apply**

```bash
chezmoi apply
zsh -i -c 'type ghq rub kctx kns kinfo rgn local-env local-zsh zprofiler zsh-bench vdoc dots devbox brewbundle _auto_dotenv _fzf_cd_ghq' 2>&1 | grep -E 'not found|not a function'
```

Expected: マッチなし（すべて定義されている）。

- [ ] **Step 5.17: ベースライン関数一覧との差分確認**

```bash
zsh -i -c 'print -l ${(k)functions} | sort' > /tmp/zsh-after-step5-functions.txt
diff /tmp/zsh-baseline-functions.txt /tmp/zsh-after-step5-functions.txt
```

Expected: 差分は worktree 関連 12 関数 (`wt`, `_wt_*`) の **削除** のみ。それ以外の関数追加/削除があれば該当箇所を再確認。

- [ ] **Step 5.18: コミット**

```bash
git add dot_config/zsh/features/ dot_zshrc.tmpl
git commit -m "$(cat <<'EOF'
refactor(zsh): split functions.zsh into features/

Decompose the 12-domain functions.zsh into 11 single-responsibility
files under dot_config/zsh/features/. The generated ~/.zshrc is
unchanged. Globals (_GHQ_CACHE, PROTECTED_BRANCHES) stay co-located
with their consumers.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: dot_zshrc.tmpl をオーケストレータに最終調整

**Why:** Task 3〜5 で各セクションが include に置換された結果、`dot_zshrc.tmpl` は冗長な分割コメントを抱えている可能性がある。最終形に整える。

**Files:**
- Modify: `dot_zshrc.tmpl`

- [ ] **Step 6.1: dot_zshrc.tmpl の最終形を確認**

期待する構造（行数約 70 行以内）:

```zsh
# =============================================================================
# Profiling (must be first)
# =============================================================================
[[ "${ZSHRC_PROFILE:-0}" == "1" ]] && zmodload zsh/zprof

# =============================================================================
# Init: 順序が意味を持つ起動シーケンス
# =============================================================================
{{ include "dot_config/zsh/init/xdg.zsh" }}
{{ include "dot_config/zsh/init/homebrew.zsh.tmpl" }}
{{ include "dot_config/zsh/init/terminal.zsh" }}
{{ include "dot_config/zsh/init/perf-flags.zsh" }}
{{ include "dot_config/zsh/init/mise.zsh" }}
{{- if .auto_tmux }}
{{ include "dot_config/zsh/init/auto-tmux.zsh.tmpl" }}
{{- end }}
{{ include "dot_config/zsh/init/p10k-instant.zsh" }}
{{ include "dot_config/zsh/init/options.zsh" }}
{{ include "dot_config/zsh/init/plugins.zsh" }}

# =============================================================================
# Aliases (declarative, no side-effects)
# =============================================================================
{{ include "dot_config/zsh/aliases.zsh" }}

# =============================================================================
# Features: 順不同 (関数定義中心)
# =============================================================================
{{ include "dot_config/zsh/features/ghq-fzf.zsh" }}
{{ include "dot_config/zsh/features/branch-cleanup.zsh" }}
{{ include "dot_config/zsh/features/kube.zsh" }}
{{ include "dot_config/zsh/features/rgn.zsh" }}
{{ include "dot_config/zsh/features/devbox-brew.zsh" }}
{{ include "dot_config/zsh/features/profiling.zsh" }}
{{ include "dot_config/zsh/features/dotenv-auto.zsh" }}
{{ include "dot_config/zsh/features/cache-mgmt.zsh" }}
{{ include "dot_config/zsh/features/dotfiles-helpers.zsh" }}
{{ include "dot_config/zsh/features/local-config-cmd.zsh" }}
{{ include "dot_config/zsh/features/documentation.zsh" }}
{{- if not .business_use }}
{{ include "dot_config/zsh/atcoder.zsh" }}
{{- end }}

# =============================================================================
# Modules: 順不同 (環境セットアップ)
# =============================================================================
{{ include "dot_config/zsh/modules/ssh-agent.zsh.tmpl" }}
{{ include "dot_config/zsh/modules/bun.zsh" }}
{{ include "dot_config/zsh/modules/pnpm.zsh" }}
{{ include "dot_config/zsh/modules/vite-plus.zsh" }}
{{ include "dot_config/zsh/modules/cf-cli.zsh" }}
{{- if not .business_use }}
{{- if and (ne .grafana_instance_id "") (ne .grafana_api_token "") }}
{{ include "dot_config/zsh/modules/telemetry.zsh.tmpl" }}
{{- end }}
{{- end }}
{{ include "dot_config/zsh/modules/local-config.zsh" }}
{{ include "dot_config/zsh/modules/p10k-config.zsh" }}

{{- if .business_use }}

# =============================================================================
# Work Environment
# =============================================================================
# Add work-specific configurations here (currently empty)
{{- end }}
```

現在の `dot_zshrc.tmpl` がこの構造になっていない場合（例: 古いコメントブロックが残っている、include 順序が違う）、上記の通りに整える。

- [ ] **Step 6.2: 行数チェック**

```bash
wc -l dot_zshrc.tmpl
```

Expected: 70 行以下。

- [ ] **Step 6.3: 構文チェック + chezmoi diff**

```bash
just lint && chezmoi diff
```

Expected:
- lint 成功
- chezmoi diff は **空** または **`~/.zshrc` のコメント・空白行整理のみ**（Task 6 はオーケストレータ整形のため、生成内容に実質的な差分は出ないはず）

- [ ] **Step 6.4: ユーザー確認 + apply**

```bash
chezmoi apply
zsh -i -c exit && echo "✓ shell starts"
```

- [ ] **Step 6.5: 全関数到達性の最終確認**

```bash
zsh -i -c 'print -l ${(k)functions} | sort' > /tmp/zsh-after-step6-functions.txt
diff /tmp/zsh-baseline-functions.txt /tmp/zsh-after-step6-functions.txt | head -30
```

Expected: 差分は worktree 関連 12 関数の削除のみ。

- [ ] **Step 6.6: 起動時間チェック**

```bash
{ for i in {1..10}; do (time zsh -i -c exit) 2>&1; done; }
```

Expected: 各回が 50ms 前後（ベースラインの 1.2 倍以内、即ち 60ms 以下）。明らかに遅くなっている場合 (e.g., 200ms) は include の重複を疑う。

- [ ] **Step 6.7: コミット (差分があれば)**

```bash
git diff --stat dot_zshrc.tmpl
```

差分がある場合のみ:
```bash
git add dot_zshrc.tmpl
git commit -m "$(cat <<'EOF'
refactor(zsh): finalize dot_zshrc.tmpl orchestrator

Polish the orchestrator to ~70 lines: profiling, init/, aliases,
features/, modules/, business-only block.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

差分なしならスキップ。

---

## Task 7: ヘッダ規約を適用

**Why:** 副作用あるファイル (init/, modules/, 副作用ある features/) に `# Provides:` `# Requires:` `# Side-effects:` `# Load-order:` ヘッダを付与する。grep で「危険なファイル」を一括検索可能にする。

**Files:**
- Modify: 全 `init/` ファイル (9 個)
- Modify: 全 `modules/` ファイル (8 個)
- Modify: 副作用ある `features/` ファイル: `ghq-fzf.zsh`, `rgn.zsh`, `dotenv-auto.zsh`

- [ ] **Step 7.1: init/xdg.zsh にヘッダ追加**

ファイル先頭に追加:

```zsh
# xdg.zsh — XDG Base Directory env vars (fallback for non-zshenv shells)
# Provides:     XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_CACHE_HOME, XDG_STATE_HOME
# Requires:     なし
# Side-effects: 上記 4 環境変数を export
# Load-order:   FIRST (他の init/* がこれらを参照)
```

- [ ] **Step 7.2: init/homebrew.zsh.tmpl にヘッダ追加**

```zsh
# homebrew.zsh.tmpl — macOS Homebrew shellenv + forbidden formulae list
# Provides:     PATH (brew bin), HOMEBREW_PREFIX, HOMEBREW_FORBIDDEN_FORMULAE
# Requires:     /opt/homebrew/bin/brew (macOS only, gracefully no-op on Linux)
# Side-effects: brew shellenv をキャッシュして source。各種環境変数を export
# Load-order:   AFTER xdg, BEFORE mise
```

- [ ] **Step 7.3: init/terminal.zsh にヘッダ追加**

```zsh
# terminal.zsh — TERM compatibility shimming
# Provides:     TERM (補正値)
# Requires:     infocmp (任意)
# Side-effects: TERM を xterm-256color または screen-256color に上書きする条件あり
# Load-order:   AFTER xdg
```

- [ ] **Step 7.4: init/perf-flags.zsh にヘッダ追加**

```zsh
# perf-flags.zsh — zsh startup performance flags
# Provides:     DISABLE_MAGIC_FUNCTIONS, skip_global_compinit
# Requires:     なし
# Side-effects: zsh global vars を設定 (zinit / oh-my-zsh の挙動に影響)
# Load-order:   BEFORE plugins (zinit が読む前)
```

- [ ] **Step 7.5: init/mise.zsh にヘッダ追加**

```zsh
# mise.zsh — mise (rtx) runtime version manager activation
# Provides:     PATH (mise shims), mise function
# Requires:     mise (任意 — 不在時は no-op)
# Side-effects: mise activate zsh の出力をキャッシュ&source
# Load-order:   AFTER homebrew (mise が brew で入る場合), BEFORE auto-tmux
```

- [ ] **Step 7.6: init/auto-tmux.zsh.tmpl にヘッダ追加**

```zsh
# auto-tmux.zsh.tmpl — auto-attach/create tmux on terminal startup
# Provides:     auto_tmux (起動時に即時実行)
# Requires:     tmux, fzf (任意)
# Side-effects: exec して shell プロセスを置換する。p10k より前必須。
#               CI/Docker 環境では no-op (DISABLE_AUTO_TMUX=1 で個別無効化可)
# Load-order:   AFTER mise (PATH に tmux), BEFORE p10k-instant
```

- [ ] **Step 7.7: init/p10k-instant.zsh にヘッダ追加**

```zsh
# p10k-instant.zsh — Powerlevel10k instant prompt loader
# Provides:     なし (p10k 内部状態を初期化)
# Requires:     ${XDG_CACHE_HOME}/p10k-instant-prompt-${USER}.zsh (初回起動時は不在で no-op)
# Side-effects: p10k instant prompt の cache を source
# Load-order:   AFTER auto-tmux (tmux 内 shell でも動作する必要), BEFORE plugins
```

- [ ] **Step 7.8: init/options.zsh にヘッダ追加**

このファイルは Task 2 で `split/options.zsh` から promote された既存ファイル。先頭には既に `# === History ===` などのセクションコメントがあるので、**それらの上**（line 1）に以下 5 行を挿入:

```zsh
# options.zsh — zsh shell options, history, key bindings
# Provides:     HISTFILE, HISTSIZE, SAVEHIST, _disable_mouse_reporting (precmd hook)
# Requires:     なし
# Side-effects: HIST 系変数 export, setopt 多数, bindkey -e, precmd hook 登録
# Load-order:   AFTER perf-flags, BEFORE plugins
```

挿入後の line 6 以降は既存のコードがそのまま残る。

- [ ] **Step 7.9: init/plugins.zsh にヘッダ追加**

このファイルも Task 2 で `split/plugins.zsh` から promote された既存ファイル。先頭の既存セクションコメント (`# === Zinit ===` など) の **上**（line 1）に以下 6 行を挿入:

```zsh
# plugins.zsh — zinit + zsh plugins (turbo mode), zoxide
# Provides:     zinit, p10k prompt, fast-syntax-highlighting,
#               zsh-autosuggestions, zsh-history-substring-search,
#               zsh-abbr (abbreviations), zoxide (z command)
# Requires:     git (zinit clone 用)
# Side-effects: ZINIT_HOME 設定、zinit clone (初回のみ)、各種プラグイン load、
#               compinit 呼出、widget 多数登録
# Load-order:   AFTER options (HIST 系変数を参照), BEFORE features/
```

- [ ] **Step 7.10: modules/ssh-agent.zsh.tmpl にヘッダ追加**

```zsh
# ssh-agent.zsh.tmpl — SSH agent setup (macOS Keychain / Linux keychain)
# Provides:     SSH_AUTH_SOCK
# Requires:     ssh-add (macOS), keychain (Linux 任意)
# Side-effects: SSH_AUTH_SOCK 設定, ssh-add で鍵を agent に追加
# Load-order:   free (interactive shell であればよい)
```

- [ ] **Step 7.11: modules/bun.zsh にヘッダ追加**

```zsh
# bun.zsh — bun completions
# Provides:     _bun (completion function)
# Requires:     ~/.bun/_bun (任意 — 不在時は no-op)
# Side-effects: compinit -C を呼んで _bun を source
# Load-order:   AFTER plugins (zinit の compinit と競合しないよう -C で skip)
```

- [ ] **Step 7.12: modules/pnpm.zsh にヘッダ追加**

```zsh
# pnpm.zsh — pnpm PATH setup
# Provides:     PNPM_HOME, PATH (pnpm bin)
# Requires:     なし
# Side-effects: PNPM_HOME export, PATH 先頭に追加 (重複防止チェックあり)
# Load-order:   free
```

- [ ] **Step 7.13: modules/vite-plus.zsh にヘッダ追加**

```zsh
# vite-plus.zsh — Vite+ env loader
# Provides:     なし (~/.vite-plus/env が定義する変数)
# Requires:     ~/.vite-plus/env (任意 — 不在時は no-op)
# Side-effects: source ~/.vite-plus/env
# Load-order:   free
```

- [ ] **Step 7.14: modules/cf-cli.zsh にヘッダ追加**

```zsh
# cf-cli.zsh — CF CLI completions (shipped via Vite+)
# Provides:     _cf (completion)
# Requires:     ~/.config/cf/completions/_cf.zsh (任意 — 不在時は no-op)
# Side-effects: source completion file
# Load-order:   AFTER vite-plus
```

- [ ] **Step 7.15: modules/telemetry.zsh.tmpl にヘッダ追加**

```zsh
# telemetry.zsh.tmpl — Claude Code OTLP → Grafana Cloud (personal only)
# Provides:     なし (export のみ)
# Requires:     grafana_instance_id, grafana_api_token, grafana_sa_token (chezmoi data)
# Side-effects: CLAUDE_CODE_ENABLE_TELEMETRY, OTEL_*, GRAFANA_SA_TOKEN を export
# Load-order:   free (claude code 起動より前であればよい)
```

- [ ] **Step 7.16: modules/local-config.zsh にヘッダ追加**

```zsh
# local-config.zsh — load machine-specific overrides
# Provides:     なし (~/.env.local / ~/.zshrc.local が定義する変数や関数)
# Requires:     ~/.env.local, ~/.zshrc.local (任意 — 不在時は no-op)
# Side-effects: source ~/.env.local; source ~/.zshrc.local
# Load-order:   AFTER 全 features/* (local override が機能を上書きできるよう最後に)
```

- [ ] **Step 7.17: modules/p10k-config.zsh にヘッダ追加**

```zsh
# p10k-config.zsh — Powerlevel10k user config loader
# Provides:     なし (~/.p10k.zsh が prompt を構成)
# Requires:     ~/.p10k.zsh (任意 — `p10k configure` で生成、不在時は no-op)
# Side-effects: source ~/.p10k.zsh
# Load-order:   LAST (全プラグイン load 後、prompt が表示される直前)
```

- [ ] **Step 7.18: features/ghq-fzf.zsh にヘッダ追加**

```zsh
# ghq-fzf.zsh — ghq + fzf repository navigation
# Provides:     ghq, _fzf_cd_ghq, repos, _GHQ_CACHE
# Requires:     ghq, fzf, bat (preview), eza (fallback)
# Side-effects: 起動時に _ghq_cache_update を背景実行 (キャッシュなし時のみ)。
#               zle widget _fzf_cd_ghq を ^g に bind。alias repos 追加
# Load-order:   AFTER plugins (zle が利用可能)
```

- [ ] **Step 7.19: features/rgn.zsh にヘッダ追加**

```zsh
# rgn.zsh — ripgrep + fzf → nvim live grep
# Provides:     rgn, _rgn_widget
# Requires:     rg (ripgrep), fzf, nvim
# Side-effects: zle widget _rgn_widget を登録 + bindkey で割り当て
# Load-order:   AFTER plugins (zle が利用可能)
```

- [ ] **Step 7.20: features/dotenv-auto.zsh にヘッダ追加**

```zsh
# dotenv-auto.zsh — auto source .env on directory change
# Provides:     _auto_dotenv
# Requires:     なし
# Side-effects: precmd hook (or chpwd_functions) を登録
# Load-order:   AFTER plugins (add-zsh-hook が利用可能)
```

- [ ] **Step 7.21: 構文チェック**

```bash
just lint
```

Expected: 構文エラーなし。

- [ ] **Step 7.22: chezmoi diff**

```bash
chezmoi diff
```

Expected: コメント追加のみ。`~/.zshrc` 生成内容と各 `~/.config/zsh/{init,modules,features}/*.zsh*` ファイルにヘッダコメント行 (5 行) が増える差分が出る。それ以外の変更がないことを確認。

- [ ] **Step 7.23: ユーザー確認 + apply**

```bash
chezmoi apply
zsh -i -c exit && echo "✓ shell starts"
```

- [ ] **Step 7.24: コミット**

```bash
git add dot_config/zsh/init/ dot_config/zsh/modules/ dot_config/zsh/features/
git commit -m "$(cat <<'EOF'
feat(zsh): add header convention to side-effecting files

Prepend Provides/Requires/Side-effects/Load-order headers to all
init/* and modules/* files, plus features/ files with side effects
(ghq-fzf, rgn, dotenv-auto). Pure-function feature files unchanged.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: justfile に lint-headers ターゲット追加

**Files:**
- Modify: `justfile`

- [ ] **Step 8.1: justfile に lint-headers ターゲット追加**

`justfile` の `# Run linters` セクション (lint ターゲット) の直後に追加:

```just
# Lint Provides header on side-effecting zsh files
lint-headers:
    @echo "Checking header convention..."
    @for f in dot_config/zsh/init/*.zsh* dot_config/zsh/modules/*.zsh*; do \
        if ! head -10 "$f" | grep -qE '^# Provides:'; then \
            echo "✗ $f: missing '# Provides:' header (top 10 lines)"; \
            exit 1; \
        fi \
    done
    @echo "✓ Headers OK!"
```

`test` ターゲットの依存に追加:

Before:
```just
test: lint fmt-check test-hooks
```

After:
```just
test: lint lint-headers fmt-check test-hooks
```

- [ ] **Step 8.2: lint-headers 単独実行で成功確認**

```bash
just lint-headers
```

Expected: `✓ Headers OK!` と出力。

- [ ] **Step 8.3: 故意に壊して fail を確認 (Red 検証)**

```bash
# 一時的に init/xdg.zsh から Provides 行を削除
sed -i.bak '/^# Provides:/d' dot_config/zsh/init/xdg.zsh
just lint-headers
```

Expected: exit code 非ゼロ、`✗ dot_config/zsh/init/xdg.zsh: missing '# Provides:' header` と表示。

復元:
```bash
mv dot_config/zsh/init/xdg.zsh.bak dot_config/zsh/init/xdg.zsh
just lint-headers
```

Expected: 再び `✓ Headers OK!`。

- [ ] **Step 8.4: 全 test ターゲット実行**

```bash
just test
```

Expected: lint, lint-headers, fmt-check, test-hooks すべて pass。

- [ ] **Step 8.5: コミット**

```bash
git add justfile
git commit -m "$(cat <<'EOF'
feat(zsh): add lint-headers CI check to justfile

Verify all dot_config/zsh/init/*.zsh* and modules/*.zsh* files have a
'# Provides:' header in the top 10 lines. Wired into 'just test' so
CI catches regressions.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: 最終検証 (Done Criteria 全項目)

**Files:** なし (検証のみ)

- [ ] **Step 9.1: ディレクトリ構造の確認**

```bash
ls dot_config/zsh/split/ 2>&1
```

Expected: `No such file or directory`。

```bash
ls dot_config/zsh/
```

Expected: `aliases.zsh atcoder.zsh features init modules` のみ。

- [ ] **Step 9.2: 行数チェック**

```bash
wc -l dot_zshrc.tmpl
wc -l dot_config/zsh/init/*.zsh* dot_config/zsh/modules/*.zsh* dot_config/zsh/features/*.zsh*
```

Expected:
- `dot_zshrc.tmpl` ≤ 70 行
- `init/`, `modules/`, `features/` 各ファイル ≤ 120 行 (ただし `init/plugins.zsh` は ~220 行で例外、spec で許容)

- [ ] **Step 9.3: ヘッダ規約遵守確認**

```bash
just lint-headers
```

Expected: `✓ Headers OK!`。

- [ ] **Step 9.4: worktree 関数の不在確認**

```bash
zsh -i -c 'for f in wt _wt_repo_basename _wt_dir _wt_guard _wt_add _wt_fzf_select _wt_rm _wt_ls _wt_cd _wt_list_names _wt_interactive _wt_usage; do
  type $f &>/dev/null && echo "✗ $f exists" || echo "✓ $f gone"
done'
```

Expected: 全 12 行が `✓ ... gone`。

- [ ] **Step 9.5: dot_tmux.conf に wt-interactive 参照なし**

```bash
grep -n 'wt-interactive\|wt_interactive' dot_tmux.conf || echo "✓ no references"
```

Expected: `✓ no references`。

- [ ] **Step 9.6: .chezmoiignore に split/ 参照なし**

```bash
grep -n 'zsh/split' .chezmoiignore || echo "✓ no references"
```

Expected: `✓ no references`。

- [ ] **Step 9.7: just test すべて pass**

```bash
just test
```

Expected: 全 check が ✓。

- [ ] **Step 9.8: chezmoi apply --dry-run**

```bash
chezmoi apply --dry-run --verbose
```

Expected: エラーなく完了。

- [ ] **Step 9.9: zsh -i -c exit が成功**

```bash
zsh -i -c exit && echo "✓ shell starts"
```

Expected: `✓ shell starts`。

- [ ] **Step 9.10: 起動時間が baseline の 1.2 倍以内**

```bash
{ for i in {1..10}; do (time zsh -i -c exit) 2>&1; done; } > /tmp/zsh-after-final-zshtime.txt
echo "Baseline:"; cat /tmp/zsh-baseline-zshtime.txt
echo "After:";    cat /tmp/zsh-after-final-zshtime.txt
```

Expected: 中央値が baseline の 1.2 倍以内（ベースラインが 50ms なら 60ms 以下）。

- [ ] **Step 9.11: 関数差分の最終確認**

```bash
zsh -i -c 'print -l ${(k)functions} | sort' > /tmp/zsh-final-functions.txt
diff /tmp/zsh-baseline-functions.txt /tmp/zsh-final-functions.txt
```

Expected: 差分は worktree 関連 12 関数の削除のみ。

- [ ] **Step 9.12: business 環境での dry-run**

```bash
BUSINESS_USE=1 chezmoi init --source=. --dry-run
```

Expected: エラーなく完了。

- [ ] **Step 9.13: PR 作成 (ユーザー確認後)**

ユーザーに以下を提示:

> 「全コミット完了 + 検証パス。PR を作成しますか？(承認時のみ実行)」

承認後:

```bash
git push -u origin <branch-name>
gh pr create --title "refactor(zsh): split dot_zshrc.tmpl + functions.zsh, drop worktree" --body "$(cat <<'EOF'
## Summary
- dot_zshrc.tmpl (250 lines) → ~70 line orchestrator
- functions.zsh (667 lines) → 11 features/* files
- New init/, modules/, features/ structure with Provides/Requires/Side-effects/Load-order headers
- Worktree feature (wt + _wt_*, popup launcher, tmux bind g) removed
- justfile lint-headers CI check added

## Done criteria
- [x] dot_config/zsh/split/ removed
- [x] dot_zshrc.tmpl ≤ 70 lines
- [x] All side-effecting files have Provides headers
- [x] worktree functions absent
- [x] just test passes
- [x] zshtime within 1.2x baseline

## Test plan
- [x] just test
- [x] chezmoi apply --dry-run
- [x] zsh -i -c exit succeeds
- [x] BUSINESS_USE=1 chezmoi init --dry-run succeeds
- [ ] CI on push (GitHub Actions)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review Notes

Spec coverage check (mapping spec sections → tasks):

| Spec section | Implementing task |
|--------------|-------------------|
| ディレクトリ構造 (`init/`/`modules/`/`features/`) | Task 3, 4, 5 |
| dot_zshrc.tmpl 縮小形 (~70 行) | Task 6 |
| ヘッダ規約 (副作用ありファイル) | Task 7 |
| CI lint-headers | Task 8 |
| worktree 廃止 | Task 1 |
| split/ 上位移動 | Task 2 |
| .chezmoiignore パス更新 | Task 2 (Step 2.4) |
| 副作用ホットスポット 5 件 | Task 1 (tmux bind g), Task 2 (.chezmoiignore), Task 5 (`_GHQ_CACHE`, `PROTECTED_BRANCHES`), 暗黙対応 (`le`/`lz` abbr) |
| マイグレーション順序 (8 ステップ) | Task 1〜8 |
| 検証チェックリスト (10 項目) | Task 9 (各 Step が 1 項目に対応) |
| Done 条件 (12 項目) | Task 9 で全項目チェック |
| ロールバック計画 | プラン外 (常に有効) |

Placeholder scan: 「TBD」「TODO」「implement later」「fill in details」なし — 確認済み。

Type/path consistency: `dot_config/zsh/init/auto-tmux.zsh.tmpl` (Task 3 と Task 7 で一致), `_GHQ_CACHE` は ghq-fzf.zsh のみ (Task 5 と Task 7 で一致)、`{{ if not .business_use }}` の条件は telemetry/atcoder で一致。
