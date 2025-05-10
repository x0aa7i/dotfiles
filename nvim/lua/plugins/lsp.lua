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
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = {
      vt_position = "end_of_line",
      text_format = function(symbol)
        if symbol.references then
          local usage = symbol.references <= 1 and "usage" or "usages"
          local num = symbol.references == 0 and "no" or symbol.references
          return string.format(" 󰌹 %s %s", num, usage)
        else
          return ""
        end
      end,
    },
  },
}
