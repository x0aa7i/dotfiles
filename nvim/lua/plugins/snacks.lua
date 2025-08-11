return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = require("utils.logos").sharp,
      },
    },
    indent = {
      enabled = true,
      indent = {
        char = "┊",
        only_current = true,
      },
      scope = {
        only_current = true,
      },
      animate = {
        enabled = false,
        easing = "linear",
        duration = {
          step = 15, -- ms per step
          total = 150, -- maximum duration
        },
      },
    },
    image = {
      enabled = false,
      math = {
        enabled = false,
      },
    },
    statuscolumn = {
      enabled = true,
      left = { "mark", "sign" }, -- priority of signs on the left (high to low)
      right = { "fold", "git" }, -- priority of signs on the right (high to low)
      folds = {
        open = false, -- show open fold icons
        git_hl = true, -- use Git Signs hl for fold icons
      },
      git = {
        -- patterns to match Git signs
        patterns = { "GitSign", "MiniDiffSign" },
      },
      refresh = 50, -- refresh at most every 50ms
    },
    picker = {
      formatters = {
        file = {
          filename_first = true, -- display filename before the file path
        },
      },
      win = {
        input = {
          keys = {
            -- close the picker on ESC instead
            ["<Esc>"] = { "close", mode = { "n", "i" } },
          },
        },
      },
    },
    zen = {
      toggles = {
        dim = false,
      },
      win = {
        backdrop = {
          transparent = false,
        },
      },
    },
    scratch = {
      win = {
        width = 130,
        height = 40,
        zindex = 50,
      },
    },
  },
  keys = {
    {
      "<leader><space>",
      function()
        Snacks.picker.smart({ multi = { "buffers", "files" } })
      end,
      desc = "Find Files (Root Dir)",
    },
    {
      "<leader>k",
      ft = { "txt", "markdown" },
      function()
        Snacks.image.hover()
      end,
      desc = "Preview image under cursor",
    },
    { "<leader>gd", false }, -- used by diffview
  },
}
