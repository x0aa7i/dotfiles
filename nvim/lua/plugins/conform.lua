return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettierd = {
          require_cwd = false,
          env = {
            PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/rules/.prettierrc.json",
          },
        },
        oxfmt = {
          cwd = require("conform.util").root_file({
            ".oxfmtrc",
            ".oxfmtrc.json",
            ".oxfmtrc.jsonc",
            "oxfmt.json",
            "oxfmt.jsonc",
          }),
          require_cwd = true,
        },
      },
      formatters_by_ft = {
        ["html"] = { "oxfmt", "prettierd", stop_after_first = true },
        ["css"] = { "oxfmt", "prettierd", stop_after_first = true },
        ["json"] = { "oxfmt", "prettierd", stop_after_first = true },
        ["yaml"] = { "oxfmt", "prettierd", stop_after_first = true },
        ["toml"] = { "oxfmt", "taplo", stop_after_first = true },
        ["typst"] = { "typstyle" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "oxfmt",
        "prettierd",
        "stylua",
      },
    },
  },
}
