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
      cmp_docs = {
        always_update = true,
      },
    },
    user_default_options = {
      -- Available modes for `mode`: foreground, background,  virtualtext
      mode = "virtualtext",
      css = true,
      css_fn = true,
      names = false,
      tailwind = false, -- "normal" | "lsp" | "both" -- true is 'normal'
      virtualtext = " ",
      virtualtext_inline = true,
    },
  },
}
