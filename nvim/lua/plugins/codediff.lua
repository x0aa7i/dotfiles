return {
  "esmuellert/codediff.nvim",
  version = "*",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = "CodeDiff",
  keys = {
    { "<leader>gd", "<cmd>CodeDiff file HEAD<CR>", desc = "Code Diff" },
  },
  opts = {
    explorer = {
      position = "left", -- "left" or "bottom"
      width = 40, -- Width when position is "left" (columns)
      height = 15, -- Height when position is "bottom" (lines)
      indent_markers = true, -- Show indent markers in tree view (│, ├, └)
      icons = {
        folder_closed = "", -- Nerd Font folder icon (customize as needed)
        folder_open = "", -- Nerd Font folder-open icon
      },
      view_mode = "tree", -- "list" or "tree"
      file_filter = {
        ignore = {}, -- Glob patterns to hide (e.g., {"*.lock", "dist/*"})
      },
    },
  },
}
