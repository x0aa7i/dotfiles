return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.tsc = opts.servers.tsc or {}
      LazyVim.extend(opts.servers.tsc, "settings.typescript.tsserver.globalPlugins", {
        {
          name = "typescript-svelte-plugin",
          location = LazyVim.get_pkg_path("svelte-language-server", "/node_modules/typescript-svelte-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      })
    end,
  },
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
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["svelte"] = { "oxfmt", "prettierd", stop_after_first = true },
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
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "svelte-language-server",
        "emmet-language-server", -- css/html completions
      },
    },
  },
}
