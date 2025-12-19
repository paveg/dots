return {
  -- GitHub Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<Tab>",
          accept_word = "<C-Right>",
          accept_line = "<C-End>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = true,
      },
      filetypes = {
        yaml = true,
        markdown = true,
        gitcommit = true,
        gitrebase = true,
        ["."] = false,
      },
    },
  },

  -- Copilot Chat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      debug = false,
    },
    keys = {
      {
        "<leader>cc",
        function()
          require("CopilotChat").toggle()
        end,
        desc = "Toggle Copilot Chat",
      },
      {
        "<leader>ce",
        function()
          require("CopilotChat").ask("Explain this code", { selection = require("CopilotChat.select").visual })
        end,
        mode = "v",
        desc = "Explain code",
      },
      {
        "<leader>cr",
        function()
          require("CopilotChat").ask("Review this code", { selection = require("CopilotChat.select").visual })
        end,
        mode = "v",
        desc = "Review code",
      },
      {
        "<leader>cf",
        function()
          require("CopilotChat").ask("Fix this code", { selection = require("CopilotChat.select").visual })
        end,
        mode = "v",
        desc = "Fix code",
      },
    },
  },
}
