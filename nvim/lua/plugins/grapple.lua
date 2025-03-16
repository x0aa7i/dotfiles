return {
  {
    "cbochs/grapple.nvim",
    enabled = false,
    opts = {
      scope = "git", -- also try out "git_branch"
      icons = true,
      status = true,
      statusline = {
        icon = "",
      },
    },
    event = { "BufReadPost", "BufNewFile" },
    cmd = "Grapple",
    keys = {
      { "<leader>ha", "<cmd>Grapple tag<cr>", desc = "Add file" },
      { "<leader>hd", "<cmd>Grapple untag<cr>", desc = "Remove file" },
      { "<leader>hl", "<cmd>Grapple toggle_tags<cr>", desc = "Open tags menu" },
      { "<leader>hh", "<cmd>Grapple toggle_tags<cr>", desc = "Open tags menu" },
      { "<leader>hx", "<cmd>Grapple reset<cr>", desc = "Clear tags from current project" },

      { "<leader>h]", "<cmd>Grapple cycle_tags next<cr>", desc = "Next Grapple tag" },
      { "<leader>h[", "<cmd>Grapple cycle_tags prev<cr>", desc = "Previous Grapple tag" },
      { "<A-]>", "<cmd>Grapple cycle_tags next<cr>", desc = "Next Grapple tag" },
      { "<A-[>", "<cmd>Grapple cycle_tags prev<cr>", desc = "Previous Grapple tag" },

      { "<A-1>", "<cmd>Grapple select index=1<cr>", desc = "Select index 1" },
      { "<A-2>", "<cmd>Grapple select index=2<cr>", desc = "Select index 2" },
      { "<A-3>", "<cmd>Grapple select index=3<cr>", desc = "Select index 3" },
      { "<A-4>", "<cmd>Grapple select index=4<cr>", desc = "Select index 4" },
      { "<A-5>", "<cmd>Grapple select index=5<cr>", desc = "Select index 5" },
      { "<A-6>", "<cmd>Grapple select index=6<cr>", desc = "Select index 6" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "grapple", icon = "" },
      },
    },
  },
}
