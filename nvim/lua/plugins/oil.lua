return {
  "stevearc/oil.nvim",
  enabled = true,
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  keys = {
    { "<leader>-", false },
    { "<leader>-", "<CMD>Oil<CR>", desc = "Open file explorer (Oil)" },
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
      -- ["q"] = "actions.close",
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
      max_height = 40,
    },
  },
}
