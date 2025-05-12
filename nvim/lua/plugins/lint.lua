return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        eslint_d = {
          condition = function(ctx)
            return vim.fs.find({ "eslint.config.js" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "eslint_d",
      },
    },
  },
}
