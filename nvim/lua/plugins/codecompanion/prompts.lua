return {
  ["Anotate"] = {
    strategy = "chat",
    description = "Adds inline documentation for code.",
    opts = {
      modes = { "v" },
      short_name = "anotate",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "user",
        content = "You are an expert software engineer. Add inline comments to the provided code explaining the purpose, parameters, and return values of each function and class. Return only the annotations.",
      },
    },
  },
  ["Review"] = {
    strategy = "chat",
    description = "Provides actionable code review feedback.",
    opts = {
      modes = { "v" },
      short_name = "review",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = [[You are an expert code reviewer. Analyze the provided code and give actionable feedback on the following areas:

          - Naming: unclear or inconsistent identifiers
          - Comments: missing, vague, or redundant notes
          - Complexity: tangled logic, deep nesting, or overcomplicated code
          - Structure: tight coupling, poor separation of concerns, or unclear organization
          - Style: formatting, naming conventions, or consistency issues
          - Redundancy: repeated code or patterns
          - Correctness: bugs, unhandled edge cases, or logical errors
          - Performance: inefficient algorithms or data structures

          For each issue, provide: 1) A one-line description of the problem. 2) A concrete recommendation or fix.
          If the code is already clean, state clearly that no issues were found. Return only the review; do not rewrite the code.]],
      },
    },
  },
  ["Enhance"] = { -- rename to "Refactor" ?
    strategy = "chat",
    description = "Optimizes code for efficiency, readability, maintainability, and best practices.",
    opts = {
      modes = { "v" },
      short_name = "enhance",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are an expert software engineer. Rewrite the provided code to improve efficiency, maintainability, readability. Optimize algorithms and data structures, use clear naming and structure, and ensure concise, consistent style. Return only the optimized code, with no explanations or annotations.",
        opts = { visible = false },
      },
    },
  },
  ["Rename"] = {
    strategy = "chat",
    description = "Improves function and variable names",
    opts = {
      modes = { "v" },
      short_name = "rename",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are an expert software engineer. Review the provided code and suggest better names for functions and variables that are unclear, generic, or non-descriptive. Follow programming best practices: names should be descriptive, concise, consistent, and reflect intent. Only list suggested replacements in a clear mapping format.",
      },
    },
  },
  ["Rewrite Journal"] = {
    strategy = "chat",
    description = "Write a journal entry.",
    opts = {
      modes = { "v" },
      short_name = "journal",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "Rewrite the journal entry in first person, keeping it direct, informal, and concise. Improve clarity, sentence structure, word choice, and flow. Preserve the original meaning and emotional tone, but remove redundancy. Split long sentences when helpful, and lightly expand underdeveloped thoughts in a natural way. Use proper grammar and punctuation, and add clear paragraph breaks for readability.",
        opts = { visible = false },
      },
    },
  },
  ["Rewrite Text"] = {
    strategy = "chat",
    description = "Rewrite the provided text.",
    opts = {
      modes = { "v" },
      short_name = "rewrite",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are a writing assistant. Rewrite the provided text to improve clarity, flow, and tone while preserving its original meaning. Make the language polished, natural, concise, and expressive. Default to a positive, confident, and conversational tone, unless instructed otherwise. Avoid being overly formal or robotic. Output only the rewritten text, without explanations or annotations.",
        opts = { visible = false },
      },
    },
  },
  ["Concise / Precision"] = {
    strategy = "chat",
    description = "Detail-preserving, for technical/factual text.",
    opts = {
      modes = { "v" },
      short_name = "precise",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are a professional editor. Rewrite the provided text so that it is concise while preserving all details, facts, and information exactly as given. Do not remove or alter any nuance. Eliminate redundancy, filler words, and overly long phrasing, but ensure the final version conveys the complete meaning of the original.",
      },
    },
  },
  ["Concise / Clarity"] = {
    strategy = "chat",
    description = "Readability-focused, for professional/client-facing text.",
    opts = {
      modes = { "v" },
      short_name = "clear",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are an expert writing assistant focused on clarity and brevity. Rewrite the provided text to make it more concise while preserving its original meaning, tone, and intent. Remove redundancy, simplify complex sentence structures, and eliminate filler words. Ensure the result is clear, professional, and easy to read. Do not add new information or explanations.",
      },
    },
  },
  ["Summary"] = {
    strategy = "chat",
    description = "captures core meaning and message in brief form.",
    opts = {
      modes = { "v" },
      short_name = "summary",
      auto_submit = true,
      user_prompt = false,
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "system",
        content = "You are a skilled summarizer. Rewrite the following text into a short, concise summary that captures its essence, meaning, and overall message. Exclude unnecessary details, examples, and repetition, while preserving the core intent and insights. The result should be clear, accurate, and easy to understand.",
      },
    },
  },
  ["Problems Unit Test"] = {
    strategy = "chat",
    description = "Write unit tests for code problems.",
    opts = {
      modes = { "v" },
      short_name = "problem",
      auto_submit = true,
      user_prompt = false,
    },
    prompts = {
      {
        role = "system",
        content = [[As a skilled software engineer specializing in writing unit tests for algorithmic coding problems follow these steps:
          1. Understand the function's purpose from the problem description.
          2. Identify several normal inputs representing typical use cases.
          3. Include edge cases: empty input min/max values or unusual inputs.
          4. Write clean idiomatic Vitest unit tests in TypeScript.
          5. Cover normal cases edge cases and applicable error handling.
          6. Return only the test code block; no explanation or extra text.]],
        opts = { visible = false },
      },
    },
  },
}
