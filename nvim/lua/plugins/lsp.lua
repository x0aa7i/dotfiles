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
    "williamboman/mason.nvim",
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
}
