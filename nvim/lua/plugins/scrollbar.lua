return {
  "lewis6991/satellite.nvim",
  event = "LazyFile",
  opts = {
    winblend = 60,
    excluded_filetypes = { "neo-tree", "dashboard" },
    handlers = {
      gitsigns = {
        enable = false,
      },
    },
  },
}
