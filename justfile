# dots - dotfiles task runner
# Run 'just' to see available commands

# Default: show help
default:
    @just --list

# Format all files
# Note: devbox.json.tmpl is a chezmoi template (mixed JSON + Go template directives).
# Rendered output is verified by fmt-check; the template itself is hand-edited.
fmt:
    @echo "Formatting Lua files..."
    @stylua dot_config/nvim/
    @echo "Formatting Markdown files (oxfmt)..."
    @git ls-files '*.md' | grep -vE 'fixtures/|NOTICE\.md|\.firecrawl/|devbox/global|pytest_cache' | xargs oxfmt --write
    @echo "✓ Done!"

# Check formatting without changes
fmt-check:
    @echo "Checking Lua format..."
    @stylua --check dot_config/nvim/
    @echo "Checking Markdown format (oxfmt)..."
    @git ls-files '*.md' | grep -vE 'fixtures/|NOTICE\.md|\.firecrawl/|devbox/global|pytest_cache' | xargs oxfmt --check
    @echo "Checking devbox.json template renders as valid JSON..."
    @chezmoi execute-template < dot_local/share/devbox/global/default/devbox.json.tmpl | python3 -c "import json,sys; json.load(sys.stdin)"
    @echo "✓ All files formatted correctly!"

# Run linters
lint:
    @echo "Checking zsh syntax..."
    @for file in dot_zshrc.tmpl dot_zshenv.tmpl; do \
        if [ -f "$file" ]; then \
            sed 's/{{{{[^}]*}}}}//g' "$file" > /tmp/check.zsh; \
            zsh -n /tmp/check.zsh && echo "✓ $file"; \
        fi \
    done
    @echo "Checking lua syntax..."
    @find dot_config/nvim -name "*.lua" -exec luac -p {} \; 2>/dev/null || true
    @echo "✓ Done!"

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

# Run all checks
test: lint lint-headers fmt-check test-hooks test-skill-scripts
    @echo "✓ All checks passed!"

# Run hook tests
test-hooks:
    @echo "Running hook tests..."
    @bash tests/hooks/run-tests.sh

# Run hermetic skill script tests (no network)
test-skill-scripts:
    @echo "Running skill script tests..."
    @bash tests/skills/pr-monitor/run-tests.sh
    @bash tests/skills/context-diet/run-tests.sh

# Run skill fetcher tests
test-skills:
    @echo "Running skill fetcher tests..."
    @bash tests/skills/equity-decision/run-tests.sh
    @bash tests/skills/japanese-ai-writing-proofreader/run-tests.sh

# Install formatter tools
install:
    @echo "Installing formatters via devbox..."
    @devbox global add stylua shfmt just
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

# Push Grafana dashboard via API
grr-push:
    #!/usr/bin/env zsh
    source ~/.zshrc 2>/dev/null
    if [[ -z "${GRAFANA_SA_TOKEN:-}" ]]; then
      echo "✗ GRAFANA_SA_TOKEN is not set. Run: source ~/.zshrc" >&2
      exit 1
    fi
    echo "Deploying Claude Code dashboard to Grafana Cloud..."
    curl -sf -X POST "https://paveg.grafana.net/api/dashboards/db" \
      -H "Authorization: Bearer $GRAFANA_SA_TOKEN" \
      -H "Content-Type: application/json" \
      -d @"$HOME/.config/grafana/dashboards/claude-code-cost.json" \
      && echo "✓ Dashboard deployed!" \
      || { echo "✗ Deploy failed." >&2; exit 1; }

# Clean all caches
clean:
    @rm -rf ~/.cache/zsh/init
    @rm -rf ~/.cache/p10k*
    @rm -f ~/.cache/devbox/shellenv.zsh
    @echo "✓ Cache cleared. Restart shell."
