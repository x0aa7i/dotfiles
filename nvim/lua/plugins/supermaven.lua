return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    enabled = true,
    build = ":SupermavenUseFree",
    keys = {
      { "<leader>at", mode = "n", vim.cmd.SupermavenToggle, desc = "Toggle suggestions" },
    },
    opts = {
      keymaps = {
        accept_word = "<C-]>",
        clear_suggestion = "<C-[>",
      },
      color = {
        suggestion_color = "#414868",
        cterm = 244,
      },
      disable_inline_completion = false, -- disables inline completion for use with cmp
      disable_keymaps = false, -- disables built in keymaps for more manual control
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local function is_supermaven_active()
        return require("supermaven-nvim.api").is_running() and "" or "󱚧 "
      end

      table.insert(opts.sections.lualine_x, { is_supermaven_active, color = { fg = "#f7768e" } })
    end,
  },
}
