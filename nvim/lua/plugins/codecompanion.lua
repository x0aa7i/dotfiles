local function slash_commands()
  local commands = {}
  for _, command in ipairs({ "buffer", "file", "help", "symbols" }) do
    commands[command] = {
      opts = {
        provider = LazyVim.pick.picker.name,
      },
    }
  end
  return commands
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
      },
    },
  },
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    optional = true,
    opts = {
      sources = {
        compat = { "codecompanion" },
        providers = {
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
            enabled = true,
          },
        },
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Companion Toggle Chat" },
      { "<leader>as", "<cmd>CodeCompanionActions<cr>", mode = "n", desc = "Companion Actions" },
      { "<leader>am", "<cmd>CodeCompanionCmd<cr>", mode = "n", desc = "Companion Command" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "Companion Edit Code" },
    },
    opts = {
      adapters = {
        groq = function()
          return require("codecompanion.adapters").extend("openai", {
            name = "groq",
            schema = {
              model = {
                -- default = "llama-3.3-70b-versatile",
                default = "qwen-2.5-coder-32b",
              },
              num_ctx = {
                default = 131072,
              },
            },
            url = "https://api.groq.com/openai/v1/chat/completions",
            env = {
              api_key = "GROQ_API_KEY",
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "groq",
          slash_commands = slash_commands(),
          keymaps = {
            close = {
              modes = { n = "q", i = "<C-c>" },
              description = "Close Chat",
            },
          },
        },
        inline = {
          adapter = "groq",
        },
        agent = {
          adapter = "groq",
        },
      },
    },
  },
}
