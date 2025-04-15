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
                default = vim.g.ai_groq_model,
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
        openrouter = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "openrouter",
            formatted_name = "OpenRouter",
            url = "https://openrouter.ai/api/v1/chat/completions",
            env = {
              api_key = "OPENROUTER_API_KEY",
            },
            schema = {
              model = {
                default = "google/gemini-2.5-pro-exp-03-25:free",
                choices = {
                  ["deepseek/deepseek-r1:free"] = { opts = { can_reason = true } }, -- context: 164K
                  ["google/gemini-2.0-flash-exp:free"] = { opts = { can_reason = true } }, -- context: 1.05M
                  ["google/gemini-2.5-pro-exp-03-25:free"] = { opts = { can_reason = true } }, -- context: 2M
                },
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "groq",
          slash_commands = slash_commands(),
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
