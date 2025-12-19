---
paths: "dot_zsh*.tmpl"
---

# Zsh Configuration Rules

## Structure

- `dot_zshenv.tmpl` - Environment variables only (loaded for all shells)
- `dot_zshrc.tmpl` - Interactive shell config (aliases, functions, plugins)

## Syntax Checking

Chezmoi templates break zsh syntax checking. CI removes template syntax before checking:
```bash
sed 's/{{[^}]*}}//g' file.tmpl > /tmp/check.zsh && zsh -n /tmp/check.zsh
```

## Performance

- Shell startup target: ~50ms
- Uses zinit turbo mode for deferred plugin loading
- Cache init scripts in `~/.cache/zsh/init/`
