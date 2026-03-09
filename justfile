# dots - dotfiles task runner
# Run 'just' to see available commands

# Default: show help
default:
    @just --list

# Format all files
fmt:
    @echo "Formatting Lua files..."
    @stylua dot_config/nvim/
    @echo "Formatting JSON files..."
    @python3 -c "import json; f='dot_local/share/devbox/global/default/devbox.json'; d=json.load(open(f)); open(f,'w').write(json.dumps(d,indent=2)+'\n')"
    @echo "✓ Done!"

# Check formatting without changes
fmt-check:
    @echo "Checking Lua format..."
    @stylua --check dot_config/nvim/
    @echo "Checking JSON format..."
    @python3 -c "import json; f='dot_local/share/devbox/global/default/devbox.json'; d=json.load(open(f)); expected=json.dumps(d,indent=2)+'\n'; actual=open(f).read(); exit(0 if expected==actual else 1)"
    @echo "✓ All files formatted correctly!"

# Run linters
lint:
    @echo "Checking zsh syntax..."
    @for file in dot_zshrc.tmpl dot_zshenv.tmpl; do \
        if [ -f "$file" ]; then \
            sed 's/\{\{[^}]*\}\}//g' "$file" > /tmp/check.zsh; \
            zsh -n /tmp/check.zsh && echo "✓ $file"; \
        fi \
    done
    @echo "Checking lua syntax..."
    @find dot_config/nvim -name "*.lua" -exec luac -p {} \; 2>/dev/null || true
    @echo "✓ Done!"

# Run all checks
test: lint fmt-check
    @echo "✓ All checks passed!"

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
