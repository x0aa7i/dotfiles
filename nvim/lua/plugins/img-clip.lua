return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  ft = "markdown",
  opts = {
    default = {
      dir_path = "Assets/Attachments",
    },
  },
  keys = {
    { "<leader>m", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
  },
}
