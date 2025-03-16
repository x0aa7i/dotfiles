local use_local = false

local base_configs = {
  quit_map = "q", -- set keymap for close the response window
  retry_map = "<c-r>", -- set keymap to re-send the current prompt
  display_mode = "split", -- The display mode. Can be "float" or "split".
  show_prompt = false, -- Shows the prompt submitted to Ollama.
  show_model = false, -- Displays which model you are using at the beginning of your chat session.
  no_auto_close = false, -- Never closes the window automatically.
  hidden = false, -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
  debug = false, -- Prints errors and the command which is run.
}

local groq_configs = {
  model = "qwen-2.5-coder-32b",
  -- model = "llama-3.3-70b-versatile",
  -- model = "deepseek-r1-distill-llama-70b",
  body = { max_tokens = 4096, temperature = 0.8, top_p = 0.95, stop = nil },
  command = function()
    local api_endpoint = "https://api.groq.com/openai/v1/chat/completions"
    local api_key = os.getenv("GROQ_API_KEY")
    local curl_cmd = "curl --silent --no-buffer -X POST"
    local header_options = "-H 'Authorization: Bearer " .. api_key .. "'"
    return curl_cmd .. " " .. header_options .. " " .. api_endpoint .. " -d $body"
  end,
  init = nil,
}

local ollama_configs = {
  model = "llama3",
  host = "localhost", -- The host running the Ollama service.
  port = "11434", -- The port on which the Ollama service is listening.
  command = function(options)
    return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
  end,
  -- Function to initialize Ollama
  -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
  -- This can also be a command string.
  -- The executed command must return a JSON object with { response, context }
  -- (context property is optional).
  init = function()
    pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
  end,
}

return {
  "David-Kunz/gen.nvim",
  cmd = { "Gen" },
  dependencies = {
    {
      "folke/which-key.nvim",
      optional = true,
      opts = {
        spec = {
          {
            mode = { "n", "v" },
            { "<leader>a", group = "+ai" },
            { "<leader>at", group = "+Gen text" },
            { "<leader>ac", group = "+Gen code" },
          },
        },
      },
    },
  },
  keys = {
    { "<leader>ag", ":Gen Generate_Input<cr>", mode = "n", desc = "Generate from Input" },
    { "<leader>ag", ":Gen Generate_Selection<cr>", mode = "v", desc = "Generate from Selection" },

    -- Text-related shortcuts
    { "<leader>ata", ":Gen Ask<cr>", mode = "v", desc = "Ask About Text" },
    { "<leader>atr", ":Gen Rewrite<cr>", mode = "v", desc = "Rewrite Text" },
    { "<leader>atc", ":Gen Make_Concise<cr>", mode = "v", desc = "Make Text Concise" },
    { "<leader>ats", ":Gen Summarize<cr>", mode = "v", desc = "Summarize Text" },
    { "<leader>ate", ":Gen Enhance_Grammar_Spelling<cr>", mode = "v", desc = "Enhance Grammar and Spelling" },
    { "<leader>atj", ":Gen Journal_Note<cr>", mode = "v", desc = "Rewrite Journal Note" },

    -- Code-related shortcuts
    { "<leader>aca", ":Gen Ask_Code<cr>", mode = "v", desc = "Ask About Code" },
    { "<leader>ace", ":Gen Enhance_Code<cr>", mode = "v", desc = "Enhance Code" },
    { "<leader>acd", ":Gen JSDoc<cr>", mode = "v", desc = "Write JSDoc" },
    { "<leader>acf", ":Gen Fix_Code<cr>", mode = "v", desc = "Fix Code" },
    { "<leader>acn", ":Gen Change_Code<cr>", mode = "v", desc = "Change Code" },
    { "<leader>act", ":Gen Write_Tests<cr>", mode = "v", desc = "Write Tests" },
  },
  config = function()
    local gen = require("gen")

    gen.prompts = {
      Ask = { prompt = "Regarding the following text, $input:\n$text" },
      Ask_Code = { prompt = "Regarding the following code, $input:\n$text" },
      Generate_Input = { prompt = "$input\nProvide a concise response." },
      Generate_Selection = { prompt = "$text\nProvide a concise response." },
      Summarize = { prompt = "Provide a concise summary of the following text:\n$text" },
      Rewrite = {
        prompt = "Improve the grammar and readability of the following text. Output only the refined text without quotes:\n$text",
        replace = true,
      },
      Enhance_Grammar_Spelling = {
        prompt = "Correct and enhance the grammar and spelling in the following text. Output only the improved text without quotes:\n$text",
        replace = true,
      },
      Make_Concise = {
        prompt = "Condense the following text to its essential points, maintaining clarity. Output only the concise version without quotes:\n$text",
        replace = true,
      },
      Journal_Note = {
        prompt = "Rewrite the following journal note to improve clarity, flow, and readability. Keep the style conversational and informal:\n$text",
      },
      Enhance_Code = {
        prompt = "Optimize and improve the following code. Consider performance, readability, and best practices. Output only the enhanced code in the format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        extract = "```$filetype\n(.-)```",
      },
      Change_Code = {
        prompt = "Modify the following code according to this instruction: $input. Output only the result in the format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        extract = "```$filetype\n(.-)```",
      },
      Fix_Code = {
        prompt = "Identify and fix any issues in the following code. Output only the corrected code in the format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        extract = "```$filetype\n(.-)```",
      },
      Write_Tests = {
        prompt = "Generate unit tests for the following code using vitest library. Do not include mocks. Output only the tests in the format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        extract = "```$filetype\n(.-)```",
      },
      JSDoc = {
        prompt = "Generate concise JSDoc comments for the following code. Output only the comments: \n```$filetype\n$text\n```",
        extract = "```$filetype\n(.-)```",
      },
    }

    if use_local then
      gen.setup(vim.tbl_deep_extend("force", ollama_configs, base_configs))
    else
      gen.setup(vim.tbl_deep_extend("force", groq_configs, base_configs))
    end
  end,
}
