# Zsh 設定再整理 — 設計ドキュメント

- **Date**: 2026-04-26
- **Scope**: `dot_zshrc.tmpl` (250 行) と `dot_config/zsh/split/functions.zsh` (667 行) の責務分離、worktree 機能の廃止
- **Out of scope**: Claude Code の rules 整理、`.claude/rules/`（プロジェクト用）と `dot_claude/rules/`（global）の命名衝突解消（別作業）

## 動機

現状の主な痛点:

1. **A: 1 ファイルが大きすぎる** — `functions.zsh` は 12 ドメイン (ghq+fzf / branch cleanup / profiling / local-config / dotfiles helper / cache mgmt / dotenv auto / kubectl helper / rgn / devbox/brew / worktree / documentation) が混在。`dot_zshrc.tmpl` も Homebrew / mise / auto_tmux / SSH agent / bun / pnpm / vite+ / cf-cli / telemetry など 11 セクションを抱えている。
2. **C: 副作用・依存が読めない** — `_GHQ_CACHE` のような暗黙のグローバル共有変数、`auto_tmux` が p10k 前にいなければならない load 順制約、`.business_use` `.auto_tmux` `.grafana_*` のような条件分岐が複数ファイルに散在。

A だけを解決すると C が悪化する（細分化が暗黙依存を見えなくする）ため、両方を同時に解消する設計が必要。

## 決定

採用案: **攻めの細分化 (1 ドメイン 1 ファイル) + ヘッダ規約**。

### サブ決定

- **ファイル順序の表現**: 番号プレフィクス不使用。`dot_zshrc.tmpl` で `{{ include }}` を明示列挙する（順序が 1 ファイルで読める／追加が必ずレビューに乗る）。
- **ヘッダ規約**: 副作用あるファイルのみ必須（`init/` 全部、`modules/` 全部、`features/` 内で副作用を持つもの）。純粋関数定義のみのファイルは省略可。
- **worktree 機能**: まるごと廃止。`wt()`、`_wt_*` 12 関数、`wt-interactive.zsh`、`dot_tmux.conf` の `bind g` を削除。

## アーキテクチャ

### ディレクトリ構造

```
dot_config/zsh/
  init/                       # 順序が意味を持つ起動シーケンス (header 必須)
    xdg.zsh
    homebrew.zsh.tmpl
    terminal.zsh
    perf-flags.zsh
    mise.zsh
    auto-tmux.zsh.tmpl        # exec 副作用 / p10k より前必須
    p10k-instant.zsh
    options.zsh               # setopt / history / keybindings
    plugins.zsh               # zinit + 全プラグイン
  modules/                    # 順不同・環境セットアップ (header 必須)
    ssh-agent.zsh.tmpl
    bun.zsh
    pnpm.zsh
    vite-plus.zsh
    cf-cli.zsh
    telemetry.zsh.tmpl
    local-config.zsh
    p10k-config.zsh
  features/                   # 関数定義中心 (副作用ある場合のみ header)
    ghq-fzf.zsh               # header 必須 (起動時 cache update)
    branch-cleanup.zsh
    kube.zsh
    rgn.zsh                   # header 必須 (ZLE widget + bindkey)
    devbox-brew.zsh
    profiling.zsh
    dotenv-auto.zsh           # header 必須 (precmd hook 登録)
    cache-mgmt.zsh
    dotfiles-helpers.zsh
    local-config-cmd.zsh
    documentation.zsh
  aliases.zsh                 # 純粋な alias のみ (top level)
  atcoder.zsh                 # personal-only 既存維持 (top level)
```

### `dot_zshrc.tmpl` の縮小形 (約 50 行)

`{{ include }}` を以下の順で列挙:

1. `[[ ZSHRC_PROFILE ]] && zmodload zsh/zprof` (最上段必須)
2. `init/*` を順序通り (xdg → homebrew → terminal → perf-flags → mise → auto-tmux (条件付) → p10k-instant → options → plugins)
3. `aliases.zsh`
4. `features/*` (順不同) + `atcoder.zsh` (条件付)
5. `modules/*` (順不同) + `telemetry.zsh.tmpl` (条件付)
6. `if .business_use` のコメントブロック（将来拡張用）

`features/` を `modules/` より前に置く理由: features は純粋関数定義で副作用ゼロ、modules は環境セットアップ。「定義 → 環境セットアップ」の順は依存方向と一致しており、`local-config-cmd.zsh` のような env を読む関数が後段の正しい状態を見られる。

### ヘッダ規約

「副作用あり」とみなす操作:
- `export`, `setopt`, `unsetopt`
- `source`, `eval`, `exec`
- `compinit`, `compdef` などの completion 初期化
- `add-zsh-hook`, `precmd`, `preexec` などの hook 登録
- `zle -N`, `bindkey`, `zinit ...` などの widget/プラグイン登録
- 起動時に走る関数呼び出し（`auto_tmux`, `_ghq_cache_update &!` など）
- グローバル変数の代入で後続ファイルから参照されるもの

副作用なし = 関数定義のみ・alias 定義のみ・local 変数のみ。

ヘッダ項目（4 項目すべて記述、副作用ありファイルでは必須）:

| 項目 | 内容 |
|------|------|
| `Provides:` | このファイルが定義する公開関数・公開変数・widget |
| `Requires:` | 必要な外部コマンドや先行ロードファイル |
| `Side-effects:` | 副作用の具体的内容（複数行可） |
| `Load-order:` | `free` または `AFTER xxx` `BEFORE yyy` |

`_*` 接頭辞の private 関数は `Provides:` に列挙しない（内部実装扱い）。

### CI チェック

`justfile` に `lint-headers` ターゲット追加。`init/`, `modules/` 配下のすべてに `# Provides:` ヘッダがあることを `head -10 | grep -qE` で検証。`features/` は強制しない（副作用ある場合のみ任意で記述）。

## 副作用ホットスポット

| 項目 | 場所 | 対応 |
|------|------|------|
| `dot_tmux.conf:105` の `bind g` が `~/.config/zsh/split/wt-interactive.zsh` を参照 | tmux 設定 | 行ごと削除（worktree 廃止） |
| `.chezmoiignore` が `.config/zsh/split/atcoder.zsh` を business 環境で除外 | chezmoi config | `.config/zsh/atcoder.zsh` へパス更新 |
| `_GHQ_CACHE` を `ghq` と `_fzf_cd_ghq` が共有 | グローバル変数 | 同じ `features/ghq-fzf.zsh` に共置で閉じる |
| `PROTECTED_BRANCHES` を `rub` が参照 | グローバル変数 | 同じ `features/branch-cleanup.zsh` に共置で閉じる |
| `_zinit_setup_abbr` の `le`/`lz` abbr が `local-env`/`local-zsh` を expand | 遅延 expand | abbr expand 時刻には関数定義済みなので OK |

## マイグレーション順序

```mermaid
graph TD
    Start[現状] --> Step1[1. worktree 削除<br>functions.zsh から _wt_*/wt 削除<br>wt-interactive.zsh 削除<br>dot_tmux.conf bind g 削除]
    Step1 --> Step2[2. features/ 作成<br>functions.zsh を 11 ファイルに分解]
    Step2 --> Step3[3. init/ + modules/ 作成<br>dot_zshrc.tmpl から 11 セクション抽出]
    Step3 --> Step4[4. split/ → 上位移動<br>options/plugins → init/<br>aliases/atcoder → top-level]
    Step4 --> Step5[5. dot_zshrc.tmpl 縮小<br>{{ include }} 列挙のみに]
    Step5 --> Step6[6. ヘッダ規約適用<br>init/ modules/ + 副作用ある features/]
    Step6 --> Step7[7. justfile に lint-headers 追加]
    Step7 --> Step8[8. .chezmoiignore パス更新]
    Step8 --> Verify[検証]
```

## 検証チェックリスト

各ステップ完了時:

1. **Syntax**: `just lint`
2. **chezmoi 整合性**: `chezmoi diff` で意図しない変更がないこと
3. **dry-run apply**: `chezmoi apply --dry-run --verbose` でエラーゼロ
4. **実 apply 後の起動**: `zsh -i -c exit` がエラーゼロで終わる
5. **関数到達性**:`type` でヒットする
   - `ghq`, `_fzf_cd_ghq`, `repos`
   - `rub`
   - `kctx`, `kns`, `kinfo`
   - `rgn`
   - `local-env`, `local-zsh`
   - `zprofiler`, `zshtime`, `zsh-clear-cache`, `zsh-update-cache`, `zsh-bench`
   - `vdoc`, `dots`, `_auto_dotenv`
   - `devbox`, `brewbundle`
   - `atcoder-login`, `atc-open`, `atc-test`, `atc-submit`, `atc-top` (personal のみ)
6. **関数不在性**: `wt`, `_wt_*` 12 関数すべてが `type` で `not found`
7. **環境変数**: `XDG_*`, `HOMEBREW_*`, `PNPM_HOME`, `OTEL_*` (personal) が export 済み
8. **起動時間**: `zshtime` 10 回平均が現状±20% 以内（目標 ~50ms 維持）
9. **CI**: `just test` パス
10. **business 環境テスト**: `BUSINESS_USE=1 chezmoi init --source=. --dry-run` でエラーなし

## PR / コミット戦略

1 PR にまとめる（個人 dotfiles で共同作業者なし、変更が機械的、レビュー側として全体像が見えるほうが副作用追跡しやすい）。1 PR 内で以下のコミット粒度に分割:

| Commit | 内容 |
|--------|------|
| 1 | `feat(zsh): remove worktree feature` |
| 2 | `refactor(zsh): split functions.zsh into features/` |
| 3 | `refactor(zsh): extract init/ and modules/ from dot_zshrc.tmpl` |
| 4 | `refactor(zsh): promote split/ files to top-level zsh dir` |
| 5 | `feat(zsh): add header convention + CI lint` |
| 6 | `chore: update .chezmoiignore for new layout` |

## ロールバック計画

破綻時は `chezmoi git -- reset --hard origin/main && chezmoi apply` で即時復旧可能。`~/.zshrc.local` `~/.env.local` は chezmoi 管理外なので影響なし。

## 完了条件 (Done Criteria)

すべて自動検証可能:

- [ ] `dot_config/zsh/split/` ディレクトリが存在しない
- [ ] `dot_zshrc.tmpl` の行数が 70 行以下
- [ ] `dot_config/zsh/init/`, `modules/`, `features/` の各ファイルが 120 行以下を目安。例外: `init/plugins.zsh` は宣言的 zinit プラグイン定義の集合で意味単位が一つのため、現状の ~220 行サイズを維持してよい
- [ ] `init/` 配下の全ファイルに `# Provides:` ヘッダがある
- [ ] `modules/` 配下の全ファイルに `# Provides:` ヘッダがある
- [ ] `wt`, `_wt_*` 関数 12 個が定義されていない
- [ ] `dot_tmux.conf` に `wt-interactive` への参照がない
- [ ] `.chezmoiignore` に `.config/zsh/split/` への参照がない
- [ ] `just test` がパスする
- [ ] `chezmoi apply --dry-run --verbose` がエラーなく完了する
- [ ] `zsh -i -c exit` がエラーゼロで終わる
- [ ] `zshtime` の起動時間中央値が現状の 1.2 倍以内
