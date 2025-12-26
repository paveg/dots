# Neovim Keybindings

> Leader Key = **Space**

## File Navigation

| Key              | Action                        |
| ---------------- | ----------------------------- |
| `<leader>e`      | Toggle file explorer          |
| `<leader>ff`     | Find files                    |
| `<leader>fg`     | Live grep search              |
| `<leader>fb`     | List buffers                  |
| `<leader>fr`     | Recent files                  |
| `<leader>fc`     | Git commits                   |
| `<leader>fs`     | Git status                    |
| `<leader>/`      | Search in current buffer      |
| `<leader><leader>` | Quick buffer switch         |

## Window & Buffer

| Key                      | Action               |
| ------------------------ | -------------------- |
| `Ctrl` + `h/j/k/l`       | Move between windows |
| `Ctrl` + `Arrow keys`    | Resize windows       |
| `Shift` + `h`            | Previous buffer      |
| `Shift` + `l`            | Next buffer          |
| `<leader>bd`             | Delete buffer        |

## LSP (Code Intelligence)

| Key          | Action                 |
| ------------ | ---------------------- |
| `gd`         | Go to definition       |
| `gr`         | Go to references       |
| `gI`         | Go to implementation   |
| `gy`         | Go to type definition  |
| `gD`         | Go to declaration      |
| `K`          | Hover documentation    |
| `<leader>rn` | Rename symbol          |
| `<leader>ca` | Code action            |
| `<leader>ds` | Document symbols       |
| `<leader>ws` | Workspace symbols      |
| `[d` / `]d`  | Prev/Next diagnostic   |
| `<leader>d`  | Show diagnostic float  |
| `<leader>q`  | Diagnostic list        |

## Git (gitsigns)

| Key          | Action          |
| ------------ | --------------- |
| `]h` / `[h`  | Next/Prev hunk  |
| `<leader>hs` | Stage hunk      |
| `<leader>hr` | Reset hunk      |
| `<leader>hp` | Preview hunk    |
| `<leader>hb` | Blame line      |

## Copilot

| Key                | Action                   |
| ------------------ | ------------------------ |
| `Tab`              | Accept suggestion        |
| `Ctrl` + `Right`   | Accept word              |
| `Ctrl` + `End`     | Accept line              |
| `Alt` + `]` / `[`  | Next/Prev suggestion     |
| `Ctrl` + `]`       | Dismiss suggestion       |
| `<leader>cc`       | Copilot Chat             |
| `<leader>ce`       | Explain code (visual)    |
| `<leader>cr`       | Review code (visual)     |
| `<leader>cf`       | Fix code (visual)        |

## Comment

| Key   | Action                         |
| ----- | ------------------------------ |
| `gcc` | Toggle line comment            |
| `gc`  | Toggle comment (motion/visual) |
| `gbc` | Toggle block comment           |

## Editing

| Key                | Action                    |
| ------------------ | ------------------------- |
| `<` / `>`          | Indent (visual, repeats)  |
| `J` / `K`          | Move line up/down (visual)|
| `ys{motion}{char}` | Surround add              |
| `ds{char}`         | Surround delete           |
| `cs{old}{new}`     | Surround change           |

## Completion

| Key                  | Action                 |
| -------------------- | ---------------------- |
| `Ctrl` + `Space`     | Trigger completion     |
| `Ctrl` + `n` / `p`   | Next/Prev item         |
| `Tab` / `Shift+Tab`  | Navigate / Expand      |
| `Enter`              | Confirm selection      |
| `Ctrl` + `e`         | Abort completion       |
| `Ctrl` + `b` / `f`   | Scroll docs            |

## Text Objects (mini.ai)

| Key         | Action                    |
| ----------- | ------------------------- |
| `af` / `if` | Function (outer/inner)    |
| `ac` / `ic` | Class                     |
| `ao` / `io` | Block/Conditional/Loop    |

## Discovery

| Key                  | Action                   |
| -------------------- | ------------------------ |
| `<leader>?`          | Show keybindings (which-key) |
| `:Telescope keymaps` | Search all keymaps       |

---

## Plugins

| Category   | Plugins                               |
| ---------- | ------------------------------------- |
| LSP        | mason, nvim-lspconfig, conform        |
| Completion | nvim-cmp, LuaSnip, friendly-snippets  |
| Navigation | telescope, nvim-tree                  |
| Git        | gitsigns                              |
| UI         | lualine, bufferline, noice, which-key |
| Theme      | tokyonight (night)                    |
| AI         | copilot, copilot-chat                 |
| Syntax     | treesitter                            |
