---
paths: "**/*.tmpl"
---

# Chezmoi Template Rules

## Template Syntax

- Use Go template syntax: `{{ .variable }}`, `{{- ... -}}` for whitespace control
- Access chezmoi data via `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.homeDir`
- Custom data defined in `.chezmoi.yaml.tmpl` accessed via `.name`, `.email`, `.business_use`, etc.

## Conditional Patterns

```
{{- if .business_use }}
# Work-specific content
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
# macOS-specific content
{{- end }}
```

## Testing Changes

`chezmoi execute-template < file.tmpl` renders with the current config and touches nothing.

**DANGER:** `chezmoi init` regenerates the real `~/.config/chezmoi/chezmoi.yaml`
**even with `--dry-run`**. A `BUSINESS_USE=1` test run (or one launched from a shell
that inherited `BUSINESS_USE=1`) silently flips the real config to business mode,
and the next `chezmoi apply` writes a business `~/.zshenv` that re-poisons every
later shell — a self-perpetuating loop. Always isolate test inits behind a
throwaway `XDG_CONFIG_HOME` with a seeded config (prompts cannot run headless):

```bash
tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/chezmoi"
printf 'data:\n  name: "Test User"\n  email: "test@example.com"\n  work_email: "test@work.example.com"\n' > "$tmpdir/chezmoi/chezmoi.yaml"
XDG_CONFIG_HOME="$tmpdir" BUSINESS_USE=1 chezmoi init --source=. --dry-run        # business mode
XDG_CONFIG_HOME="$tmpdir" env -u BUSINESS_USE chezmoi init --source=. --dry-run   # personal mode
```

Recovery if the real config got flipped: `env -u BUSINESS_USE chezmoi init
--source ~/.local/share/chezmoi && env -u BUSINESS_USE chezmoi apply`, then kill
the tmux server and restart shells (inherited env survives `exec $SHELL -l`).
