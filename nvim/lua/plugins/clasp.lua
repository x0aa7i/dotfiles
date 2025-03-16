return {
  "xzbdmw/clasp.nvim",
  enabled = true,
  event = "InsertEnter",
  opts = {
    pairs = { ["{"] = "}", ['"'] = '"', ["'"] = "'", ["("] = ")", ["["] = "]", ["<"] = ">" },
    -- If called from insert mode, do not return to normal mode.
    keep_insert_mode = true,
  },
  keys = {
    {
      "<A-l>",
      function()
        require("clasp").wrap("next")
      end,
      desc = "Clasp wrap next",
      mode = { "n", "i" },
    },
    {
      "<A-h>",
      function()
        require("clasp").wrap("prev")
      end,
      desc = "Clasp wrap prev",
      mode = { "n", "i" },
    },
  },
}
