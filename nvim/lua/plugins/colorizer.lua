return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  keys = {
    { "<leader>uH", "<CMD>ColorizerToggle<CR>", desc = "Toggle Colorizer highlights" },
  },
  opts = {
    filetypes = {
      "css",
      "scss",
      html = { names = false },
      "svelte",
      "javascript",
      "typescript",
      "lua",
      "json",
      "yaml",
      "toml",
      "tmux",
    },
    options = {
      parsers = {
        css_fn = true,
        css = true,
        tailwind = {
          enable = false,
        },
      },
      display = {
        mode = "virtualtext",
        virtualtext = {
          char = " ",
          position = "eol", -- "eol"|"before"|"after"
        },
      },
    },
  },
}
