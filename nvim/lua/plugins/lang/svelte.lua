return {
  {
    "nvim-svelte/nvim-svelte-snippets",
    dependencies = "L3MON4D3/LuaSnip",
    Event = "InsertEnter",
    opts = {
      enabled = true, -- Enable/disable snippets globally
      auto_detect = true, -- Only load in SvelteKit projects
      prefix = "kit", -- Prefix for TypeScript snippets (e.g., kit-load)
    },
  },
  {
    "nvim-svelte/nvim-svelte-check",
    cmd = { "SvelteCheck" },
    opts = {
      command = "pnpm run check",
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["svelte"] = { "prettierd" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        svelte = { "eslint_d" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "svelte-language-server",
        "emmet-language-server", -- css/html completions
      },
    },
  },
}
