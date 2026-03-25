return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "b0o/schemastore.nvim",
    },
    config = function()
      -- Setup Mason first
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",
          "cssls",
          "gopls",
          "html",
          "jsonls",
          "lua_ls",
          "pyright",
          "ruby_lsp",
          "rust_analyzer",
          "sorbet",
          "taplo",
          "terraformls",
          "ts_ls",
          "yamlls",
        },
        automatic_installation = true,
      })

      -- LSP keymaps (set when LSP attaches)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", require("telescope.builtin").lsp_definitions, "Goto Definition")
          map("gr", require("telescope.builtin").lsp_references, "Goto References")
          map("gI", require("telescope.builtin").lsp_implementations, "Goto Implementation")
          map("gy", require("telescope.builtin").lsp_type_definitions, "Goto Type Definition")
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace Symbols")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("gD", vim.lsp.buf.declaration, "Goto Declaration")
        end,
      })

      -- LSP capabilities (for blink.cmp)
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Setup servers using vim.lsp.config (Neovim 0.11+)
      -- Lua
      vim.lsp.config.lua_ls = {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            diagnostics = {
              globals = { "vim" },
            },
            completion = {
              callSnippet = "Replace",
            },
          },
        },
      }

      -- TypeScript
      vim.lsp.config.ts_ls = {
        capabilities = capabilities,
      }

      -- Go
      vim.lsp.config.gopls = {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      }

      -- Rust
      vim.lsp.config.rust_analyzer = {
        capabilities = capabilities,
      }

      -- Python
      vim.lsp.config.pyright = {
        capabilities = capabilities,
      }

      -- Ruby
      vim.lsp.config.ruby_lsp = {
        capabilities = capabilities,
      }

      -- Ruby (Sorbet for type checking)
      vim.lsp.config.sorbet = {
        capabilities = capabilities,
      }

      -- Bash/Zsh
      vim.lsp.config.bashls = {
        capabilities = capabilities,
        filetypes = { "sh", "bash", "zsh" },
      }

      -- TOML
      vim.lsp.config.taplo = {
        capabilities = capabilities,
      }

      -- YAML
      vim.lsp.config.yamlls = {
        capabilities = capabilities,
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      }

      -- JSON
      vim.lsp.config.jsonls = {
        capabilities = capabilities,
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      }

      -- HTML
      vim.lsp.config.html = {
        capabilities = capabilities,
      }

      -- CSS
      vim.lsp.config.cssls = {
        capabilities = capabilities,
      }

      -- Terraform
      vim.lsp.config.terraformls = {
        capabilities = capabilities,
      }

      -- MoonBit (not managed by mason, uses system `moon lsp`)
      vim.lsp.config.moonbit_lsp = {
        cmd = { "moon", "lsp" },
        filetypes = { "moonbit" },
        root_markers = { "moon.mod.json" },
        capabilities = capabilities,
      }

      -- Enable all configured servers
      vim.lsp.enable({
        "bashls",
        "cssls",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "moonbit_lsp",
        "pyright",
        "ruby_lsp",
        "rust_analyzer",
        "sorbet",
        "taplo",
        "terraformls",
        "ts_ls",
        "yamlls",
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        css = { "prettier" },
        go = { "gofumpt", "goimports" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        moonbit = { "moonfmt" },
        python = { "ruff_fix", "ruff_format" },
        ruby = { "stree" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        terraform = { "terraform_fmt" },
        toml = { "taplo" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        yaml = { "prettier" },
        zsh = { "shfmt" },
      },
      formatters = {
        moonfmt = {
          command = "moonfmt",
          args = { "$FILENAME" },
          stdin = false,
        },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
