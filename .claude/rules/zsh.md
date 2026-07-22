---
paths:
  - "dot_zsh*.tmpl"
  - "dot_config/zsh/**"
---

# Zsh Configuration Rules

## Structure

- `dot_zshenv.tmpl` - Environment variables only (loaded for all shells)
- `dot_zshrc.tmpl` - Interactive shell config; loads every `dot_config/zsh/` file via explicit `{{ include }}` lines (a new file there is a no-op until registered)
- `dot_config/zsh/` layer (init/ features/ modules/, header convention): see docs/superpowers/specs/2026-04-26-zsh-restructure-design.md

## Syntax Checking

Chezmoi templates break zsh syntax checking. CI removes template syntax before checking:

```bash
sed 's/{{[^}]*}}//g' file.tmpl > /tmp/check.zsh && zsh -n /tmp/check.zsh
```

## Performance

- Shell startup target: ~50ms
- Uses zinit turbo mode for deferred plugin loading
- Cache init scripts in `~/.cache/zsh/init/`
