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

      -- Server configs; capabilities are injected for all entries below.
      local servers = {
        bashls = { filetypes = { "sh", "bash", "zsh" } },
        cssls = {},
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        html = {},
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
              },
              diagnostics = { globals = { "vim" } },
              completion = { callSnippet = "Replace" },
            },
          },
        },
        -- MoonBit (not managed by mason, uses system `moon lsp`)
        moonbit_lsp = {
          cmd = { "moon", "lsp" },
          filetypes = { "moonbit" },
          root_markers = { "moon.mod.json" },
        },
        pyright = {},
        ruby_lsp = {},
        rust_analyzer = {},
        sorbet = {},
        taplo = {},
        terraformls = {},
        ts_ls = {},
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
      }

      for name, config in pairs(servers) do
        config.capabilities = capabilities
        vim.lsp.config[name] = config
      end

      vim.lsp.enable(vim.tbl_keys(servers))
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
