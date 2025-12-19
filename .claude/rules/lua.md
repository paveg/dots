---
paths: "dot_config/nvim/**/*.lua"
---

# Neovim Lua Rules

## Formatting

- Format with stylua (config in `.stylua.toml`)
- Run `just fmt` before committing

## Plugin Structure

Plugins are organized in `dot_config/nvim/lua/plugins/`:
- One file per plugin category (ui.lua, editor.lua, lsp.lua, etc.)
- Uses lazy.nvim plugin manager with lazy-loading

## Style

- Prefer `vim.keymap.set()` over `vim.api.nvim_set_keymap()`
- Use `<leader>` (Space) for custom keybindings
- Group related options with comments
