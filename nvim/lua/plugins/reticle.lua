-- NVIM plugin to highlight only the screen line of the cursor in the currently active window
return {
  "tummetott/reticle.nvim",
  event = "VeryLazy", -- optionally lazy load the plugin
  opts = {
    -- Define filetypes which are ignored by the plugin
    never = {
      cursorline = {
        "DressingInput",
        "TelescopePrompt",
        "alpha",
        "snacks_dashboard",
        "dashboard",
        "toggleterm",
        "noice",
        "lazy",
        "notify",
        "yazi",
      },
    },
    always = {
      cursorline = {
        "neo-tree",
      },
    },
  },
}
