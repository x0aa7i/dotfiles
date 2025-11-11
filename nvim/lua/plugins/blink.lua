return {
  "saghen/blink.cmp",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "enter",
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" }, -- conflic with LSP Signature in svelte files

      ["<C-l>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },

      ["<Tab>"] = {
        LazyVim.cmp.map({ "ai_accept", "snippet_forward" }),
        "fallback",
      },
      -- stylua: ignore start
      ['<A-1>'] = { function(cmp) cmp.accept({ index = 1 }) end },
      ['<A-2>'] = { function(cmp) cmp.accept({ index = 2 }) end },
      ['<A-3>'] = { function(cmp) cmp.accept({ index = 3 }) end },
      ['<A-4>'] = { function(cmp) cmp.accept({ index = 4 }) end },
      ['<A-5>'] = { function(cmp) cmp.accept({ index = 5 }) end },
      ['<A-6>'] = { function(cmp) cmp.accept({ index = 6 }) end },
      ['<A-7>'] = { function(cmp) cmp.accept({ index = 7 }) end },
      ['<A-8>'] = { function(cmp) cmp.accept({ index = 8 }) end },
      ['<A-9>'] = { function(cmp) cmp.accept({ index = 9 }) end },
      -- stylua: ignore end
    },
    completion = {
      menu = {
        auto_show = true,
        draw = {
          align_to = "label",
          treesitter = { "lsp" },
          columns = { { "kind_icon" }, { "label", gap = 1 } },
        },
      },
      ghost_text = { enabled = false },
    },

    sources = {
      providers = {
        lsp = {
          opts = {
            tailwind_color_icon = "󱓻",
          },
        },
      },
    },
  },
}
