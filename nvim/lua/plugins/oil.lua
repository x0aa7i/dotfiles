return {
  "stevearc/oil.nvim",
  enabled = true,
  -- Optional dependencies
  dependencies = { "nvim-mini/mini.icons" },
  keys = {
    { "<leader>-", false },
    { "<leader>-", "<CMD>Oil --float<CR>", desc = "Open file explorer (Oil)" },
  },
  opts = {
    columns = {
      "icon",
      -- "permissions",
      -- "size",
      -- "mtime",
    },
    delete_to_trash = true,
    keymaps = {
      ["Q"] = "actions.close",
      ["<C-s>"] = false,

      --   ["<C-v>"] = "actions.select_vsplit",
      --   ["<C-x>"] = "actions.select_split",
      --   ["<C-y>"] = "actions.copy_entry_path",
    },
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 2,
      max_width = 100,
      max_height = 36,
    },
  },
}
