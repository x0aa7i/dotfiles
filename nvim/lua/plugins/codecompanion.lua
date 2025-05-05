local function format_code_block(context)
  local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
  local lang = context.filetype or ""
  return "\n```" .. lang .. "\n" .. code .. "\n```\n\n"
end

local PROMPT_LIBRARY = {
  ["Document"] = {
    strategy = "chat",
    description = "Write documentation for code.",
    opts = {
      modes = { "v" },
      short_name = "doc",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = "user",
        content = function(context)
          return "Document the following code with inline comments explaining the purpose, parameters, and return values of each function and class. Suggest clearer, more descriptive names to improve readability.\n"
            .. format_code_block(context)
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ["Review"] = {
    strategy = "chat",
    description = "Review the provided code snippet.",
    opts = {
      modes = { "v" },
      short_name = "review",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = "system",
        content = table.concat({
          "You are an expert code reviewer focused on improving code readability, maintainability, and clarity.",
          "Your goal is to help developers write understandable, modifiable, and debuggable code through constructive feedback and specific suggestions.",
          "Your task is to analyze the provided code snippet and identify issues such as:",
          "",
          "- Naming: Unclear, misleading, inconsistent, or excessively long names for variables, functions, or classes.",
          "- Comments: Unnecessary comments, missing contextual explanations, or lack of clarity.",
          "- Complexity: Overly complex logic, deep nesting, or convoluted expressions that could be simplified.",
          "- Structure: Poor modularity or organization that hinders understanding and future changes.",
          "- Style: Inconsistent formatting or deviations from best practices.",
          "- Redundancy: Repetitive code that could be abstracted or optimized.",
          "",
          "For each issue, provide:",
          "1. A brief description of the problem.",
          "2. A specific, actionable suggestion for improvement.",
          "",
          "If the code is already clean and well-written, state that explicitly.",
          "Keep feedback concise, constructive, and focused on tangible improvements.",
        }, "\n"),
        opts = {
          visible = false,
        },
      },
      {
        role = "user",
        content = function(context)
          return "Review the following code, suggest improvements, and refactor it to enhance clarity and readability.\n"
            .. format_code_block(context)
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ["Enhance"] = {
    strategy = "chat",
    description = "Enhance the provided code snippet.",
    opts = {
      modes = { "v" },
      short_name = "enhance",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = "system",
        content = table.concat({
          "You are an expert code optimizer focused on improving efficiency, clarity, and adherence to best practices.",
          "Analyze the provided code and enhance it by:",
          "",
          "1. Improving performance through efficient algorithms and data structures.",
          "2. Enhancing maintainability through better organization, naming, and structure. ",
          "3. Increasing readability with clear and concise code.",
          "4. Ensuring consistency with coding best practices for the given language.",
          "",
          "Output only the optimized code in the original format, with no additional explanations.",
        }, "\n"),
        opts = {
          visible = false,
        },
      },
      {
        role = "user",
        content = function(context)
          return "Optimize the following code for performance, readability, and best practices. Return only the improved code in the same format.\n"
            .. format_code_block(context)
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
}

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
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Companion Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Companion Toggle Chat" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "Companion Edit Code" },
    },
    opts = {
      prompt_library = PROMPT_LIBRARY,
      adapters = {
        groq = function()
          return require("codecompanion.adapters").extend("openai", {
            name = "groq",
            formatted_name = "Groq",
            url = "https://api.groq.com/openai/v1/chat/completions",
            env = {
              api_key = "GROQ_API_KEY",
            },
            schema = {
              model = {
                default = vim.g.ai_groq_model,
              },
            },
            max_tokens = { default = 8192 },
            temperature = { default = 1 },
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
