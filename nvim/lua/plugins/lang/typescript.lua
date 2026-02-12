local ts_filetypes = {
  "typescript",
  "typescriptreact",
  "javascript",
  "javascriptreact",
  "vue",
  "svelte",
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            vtsls = {
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                  entriesLimit = 30,
                },
              },
            },
            typescript = {
              preferences = {
                includePackageJsonAutoImports = "off",
              },
              tsserver = {
                maxTsServerMemory = 8192,
              },
            },
          },
        },
      },
    },
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "vtsls",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "prettierd" },
        ["javascriptreact"] = { "prettierd" },
        ["typescript"] = { "prettierd" },
        ["typescriptreact"] = { "prettierd" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
      },
    },
  },
  {
    "dmmulroy/tsc.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = { "neovim/nvim-lspconfig" },
    ft = ts_filetypes,
    keys = {
      { "<leader>ct", "<cmd>TSC<cr>", desc = "Type Check" },
      { "<leader>xy", "<cmd>TSCOpen<cr>", desc = "Type Check Quickfix" },
    },
    opts = {
      auto_start_watch_mode = false,
      use_trouble_qflist = true,
      flags = {
        watch = false,
      },
    },
    cmd = {
      "TSC",
      "TSCOpen",
      "TSCClose",
      "TSStop",
    },
  },
}
