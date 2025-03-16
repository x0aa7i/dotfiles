return {
  "chrisgrieser/nvim-chainsaw",
  opts = {
    marker = "",
  },
  keys = {
    { "<leader>d", "", desc = "debug print" },
    {
      "<leader>dv",
      function()
        require("chainsaw").variableLog()
      end,
      desc = "log variable",
    },
    {
      "<leader>db",
      function()
        require("chainsaw").beepLog()
      end,
      desc = "log beep",
    },
    {
      "<leader>do",
      function()
        require("chainsaw").objectLog()
      end,
      desc = "log object",
    },
    {
      "<leader>dt",
      function()
        require("chainsaw").timeLog()
      end,
      desc = "log time",
    },
    {
      "<leader>da",
      function()
        require("chainsaw").assertLog()
      end,
      desc = "log assert",
    },
    {
      "<leader>dc",
      function()
        require("chainsaw").removeLogs()
      end,
      desc = "remove logs",
    },
  },
}
