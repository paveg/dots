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

Always test template changes with both environments:
```bash
chezmoi execute-template < file.tmpl              # Test with current config
BUSINESS_USE=1 chezmoi init --source=. --dry-run  # Test business mode
```
