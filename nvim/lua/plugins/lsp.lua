return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cl", group = "LSP", icon = LazyVim.config.icons.diagnostics.Info },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<leader>cli", "<cmd>LspInfo<cr>", desc = "Info" },
      { "<leader>clr", "<cmd>LspRestart<cr>", desc = "Restart" },
    },
    opts = {
      inlay_hints = {
        enabled = false,
      },
    },
  },
  {
    "mason-org/mason.nvim",
    version = "1.*",
    opts = {
      ui = {
        border = "rounded",
      },
      ensure_installed = {
        "glsl_analyzer", -- glsl lsp
        "json-lsp",
        "lua-language-server",
        "taplo", -- toml lsp
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    version = "1.*",
  },
}
