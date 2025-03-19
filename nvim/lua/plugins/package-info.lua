return {
  {
    "vuki656/package-info.nvim",
    dependencies = { "folke/which-key.nvim", "MunifTanjim/nui.nvim" },
    event = { "BufRead package.json" },
    ft = "json",
    opts = {
      colors = {
        up_to_date = "#B1D99C", -- Text color for up to date dependency virtual text
        outdated = "#EAAC86", -- Text color for outdated dependency virtual text
      },

      icons = {
        enable = true, -- Whether to display icons
        style = {
          up_to_date = "|  ", -- Icon for up to date dependencies
          outdated = "|  ", -- Icon for outdated dependencies
        },
      },
      autostart = true, -- Whether to autostart when `package.json` is opened
      hide_up_to_date = true, -- It hides up to date versions when displaying virtual text
      hide_unstable_versions = false, -- It hides unstable versions from version list e.g next-11.1.3-canary3
      package_manager = "pnpm",
    },
    keys = {
      -- stylua: ignore start
      { "<leader>pp", function() require("package-info").toggle() end, desc = "Toggle package info" },
      { "<leader>ps", function() require("package-info").show() end, desc = "Show package info" },
      { "<leader>ph", function() require("package-info").hide() end, desc = "Hide package info" },
      { "<leader>pu", function() require("package-info").update() end, desc = "Update package" },
      { "<leader>pd", function() require("package-info").delete() end, desc = "Delete package" },
      { "<leader>pi", function() require("package-info").install() end, desc = "Install package" },
      { "<leader>pv", function() require("package-info").change_version() end, desc = "Change package version" },
      -- stylua: ignore end
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>p", group = "package-info", icon = "" },
      },
    },
  },
}
