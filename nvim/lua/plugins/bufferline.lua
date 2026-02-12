return {
  "akinsho/bufferline.nvim",
  event = "BufEnter",
  keys = {
    { "<S-h>", false },
    { "<S-l>", false },
    { "<tab>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<S-tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
  },
  opts = function(_, opts)
    opts.options.always_show_bufferline = true
  end,
}
