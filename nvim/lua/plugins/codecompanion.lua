return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "<leader>a", group = "+ai" },
        },
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
    version = "*",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "folke/noice.nvim",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Companion Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Companion Toggle Chat" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "Companion Edit Code" },
    },
    init = function()
      require("plugins.codecompanion.notification").init()
    end,
    opts = {
      prompt_library = require("plugins.codecompanion.prompts"),
      system_prompt = false,
      display = {
        chat = { start_in_insert_mode = true },
        action_palette = { provider = "default" },
        diff = {
          enabled = true,
          provider = "default",
        },
      },
      adapters = {
        groq = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "groq",
            formatted_name = "Groq",
            env = {
              url = "https://api.groq.com/openai",
              api_key = "GROQ_API_KEY",
              chat_url = "/v1/chat/completions", -- optional: default value, override if different
              models_endpoint = "/v1/models", -- optional: attaches to the end of the URL to form the endpoint to retrieve models
            },
            schema = {
              model = {
                default = vim.g.ai_groq_model,
              },
            },
            max_tokens = { default = 4096 },
            temperature = { default = 0.6 }, --
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
          adapter = "gemini",
          keymaps = {
            send = {
              callback = function(chat)
                vim.cmd("stopinsert")
                chat:submit()
              end,
              description = "Send",
            },
            close = {
              modes = { n = "q" },
              callback = "keymaps.close",
              description = "Close Chat",
            },
            stop = {
              modes = { n = "<C-c>" },
              callback = "keymaps.stop",
              description = "Stop Request",
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
