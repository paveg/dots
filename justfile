# dots - dotfiles task runner
# Run 'just' to see available commands

# Default: show help
default:
    @just --list

# Format all files
# Note: devbox.json.tmpl is a chezmoi template (mixed JSON + Go template directives).
# Rendered output is verified by test-devbox; the template itself is hand-edited.
fmt:
    @echo "Formatting Lua files..."
    @stylua home/dot_config/nvim/
    @echo "Formatting Markdown files (oxfmt)..."
    @git ls-files '*.md' | grep -vE 'fixtures/|NOTICE\.md|\.firecrawl/|devbox/global|pytest_cache' | xargs oxfmt --write
    @echo "✓ Done!"

# Check formatting without changes
fmt-check:
    @echo "Checking Lua format..."
    @stylua --check home/dot_config/nvim/
    @echo "Checking Markdown format (oxfmt)..."
    @git ls-files '*.md' | grep -vE 'fixtures/|NOTICE\.md|\.firecrawl/|devbox/global|pytest_cache' | xargs oxfmt --check
    @echo "✓ All files formatted correctly!"

# Run linters
lint: lint-zsh lint-lua
    @echo "✓ Done!"

# Check tracked zsh sources using the current runner OS.
# The conditional chezmoi CI matrix separately expands templates on macOS and Linux.
lint-zsh:
    #!/usr/bin/env bash
    set -euo pipefail

    for command in chezmoi git zsh; do
      if ! command -v "$command" >/dev/null 2>&1; then
        echo "✗ Required command not found: $command" >&2
        exit 1
      fi
    done

    echo "Checking tracked zsh files..."
    while IFS= read -r -d '' file; do
      zsh -n "$file"
      echo "✓ $file"
    done < <(git ls-files -z '*.zsh')

    echo "Rendering zsh templates with isolated test data..."
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    printf '{}\n' > "$tmpdir/chezmoi.json"

    render_and_check() {
      local label="$1"
      local repo_template="$2"
      local data="$3"
      local rendered="$tmpdir/$label-${repo_template//\//-}"

      chezmoi \
        --config "$tmpdir/chezmoi.json" \
        --config-format json \
        --source "$PWD" \
        --override-data "$data" \
        execute-template --file "$repo_template" > "$rendered"
      zsh -n "$rendered"
      echo "✓ $repo_template ($label, current runner OS)"
    }

    # Render each nested template directly so it cannot hide behind a false
    # condition in a top-level template.
    standalone_data='{"business_use":false,"auto_tmux":false,"homebrew_prefix":"/opt/homebrew"}'
    while IFS= read -r -d '' template; do
      render_and_check standalone "$template" "$standalone_data"
    done < <(git ls-files -z 'home/*.zsh.tmpl')

    # Render the complete top-level shell configuration for each data branch.
    for profile in personal-basic personal-telemetry business; do
      case "$profile" in
        personal-basic)
          data='{"business_use":false,"auto_tmux":false,"homebrew_prefix":"/opt/homebrew"}'
          ;;
        personal-telemetry)
          data='{"business_use":false,"auto_tmux":false,"homebrew_prefix":"/opt/homebrew"}'
          ;;
        business)
          data='{"business_use":true,"auto_tmux":true,"homebrew_prefix":"/opt/homebrew"}'
          ;;
      esac
      while IFS= read -r -d '' template; do
        render_and_check "$profile" "$template" "$data"
      done < <(git ls-files -z 'home/dot_z*.tmpl' 'home/private_dot_z*.tmpl')
    done

# Check Lua syntax. CI explicitly sets LUA_COMPILER=luac5.4 on Ubuntu.
lint-lua:
    #!/usr/bin/env bash
    set -euo pipefail

    lua_compiler="${LUA_COMPILER:-luac}"
    if ! command -v "$lua_compiler" >/dev/null 2>&1; then
      echo "✗ Lua compiler not found: $lua_compiler" >&2
      exit 1
    fi

    echo "Checking Lua syntax with $lua_compiler..."
    while IFS= read -r -d '' file; do
      "$lua_compiler" -p "$file"
      echo "✓ $file"
    done < <(git ls-files -z 'home/dot_config/nvim/*.lua' 'home/dot_config/nvim/**/*.lua')

# Lint Provides header on zsh files (init/, modules/, features/)
lint-headers:
    @echo "Checking header convention..."
    @for f in home/dot_config/zsh/init/*.zsh* home/dot_config/zsh/modules/*.zsh* home/dot_config/zsh/features/*.zsh; do \
        if ! head -10 "$f" | grep -qE '^# Provides:'; then \
            echo "✗ $f: missing '# Provides:' header (top 10 lines)"; \
            exit 1; \
        fi \
    done
    @echo "✓ Headers OK!"

# Fast, hermetic checks that run unconditionally in CI.
quality-gate: lint lint-headers test-devbox test-hooks test-zsh-features test-skill-scripts
    @echo "✓ Fast quality gate passed!"

# Run all checks
test: quality-gate fmt-check
    @echo "✓ All checks passed!"

# Run hook tests
test-hooks:
    @echo "Running hook tests..."
    @bash tests/hooks/run-tests.sh

# Run hermetic zsh feature tests
test-zsh-features:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Running zsh feature tests..."
    test_count=0
    for test_file in tests/zsh/*.test.sh; do
      [[ -f "$test_file" ]] || {
        echo "No zsh feature tests found." >&2
        exit 1
      }
      bash "$test_file"
      test_count=$((test_count + 1))
    done
    echo "✓ $test_count zsh feature test files passed!"

# Render and validate both Devbox profiles without touching user state
test-devbox:
    @echo "Validating rendered Devbox profiles..."
    @bash tests/devbox/render-and-assert.sh

# Run hermetic skill script tests (no network)
test-skill-scripts:
    @echo "Running skill script tests..."
    @bash tests/skills/pr-monitor/run-tests.sh
    @bash tests/skills/context-diet/run-tests.sh
    @bash tests/skills/codex-subagent/run-tests.sh

# Run skill fetcher tests
test-skills:
    @echo "Running skill fetcher tests..."
    @bash tests/skills/equity-decision/run-tests.sh
    @bash tests/skills/writing-proofread/run-tests.sh

# Install local quality-gate and formatter tools
install:
    @echo "Installing quality-gate and formatter tools via devbox..."
    @devbox global add stylua shfmt just lua54Packages.lua@5.4.7
    @echo "✓ Done!"

# Apply dotfiles (dry-run)
apply-dry:
    @chezmoi apply --dry-run --verbose

# Apply dotfiles
apply:
    @chezmoi apply

# Show diff
diff:
    @chezmoi diff

# Edit chezmoi source
edit file:
    @chezmoi edit {{file}}

# Update dotfiles from remote
update:
    @chezmoi update

# Clean all caches
clean:
    #!/usr/bin/env bash
    set -euo pipefail

    cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
    rm -rf "$cache_home/zsh/init"
    rm -rf "$cache_home"/p10k*
    rm -f "$cache_home/devbox/shellenv.zsh"
    rm -f "$cache_home/devbox/shellenv-pure.zsh"
    echo "✓ Cache cleared. Restart shell."
