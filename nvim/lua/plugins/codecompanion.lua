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
        http = {
          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              schema = {
                model = {
                  default = "gemma-4-26b-a4b-it",
                  choices = {
                    "gemma-4-31b-it",
                    "gemma-4-26b-a4b-it",
                    "gemini-3.1-flash-lite-preview",
                  },
                },
              },
            })
          end,
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
                  default = "openai/gpt-oss-120b",
                  choices = {
                    "openai/gpt-oss-120b",
                    "llama-3.3-70b-versatile",
                    "qwen/qwen3-32b",
                    "groq/compound",
                  },
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
                  default = "google/gemma-4-26b-a4b-it:free",
                  choices = {
                    "nvidia/nemotron-3-nano-30b-a3b:free",
                    "openai/gpt-oss-120b:free",
                    "google/gemma-4-26b-a4b-it:free",
                    "minimax/minimax-m2.5:free",
                    "google/gemma-4-31b-it:free",
                  },
                },
              },
            })
          end,
        },
      },
      strategies = {
        chat = {
          -- adapter = "groq",
          adapter = "gemini",
          -- adapter = "openrouter",
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
