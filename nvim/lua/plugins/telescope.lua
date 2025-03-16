return {
  {
    "nvim-telescope/telescope.nvim",
    enabled = false,
    dependencies = {
      -- "debugloop/telescope-undo.nvim",
      -- "nvim-lua/plenary.nvim", -- telescope undo dependency
      {
        "danielfalk/smart-open.nvim",
        branch = "0.2.x",
        dependencies = { "kkharji/sqlite.lua" },
      },
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope smart_open<cr>", desc = "Smart Open" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      -- { "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undos" },
    },
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults.layout_strategy = "flex"
      opts.defaults.layout_config = {
        prompt_position = "bottom",
        vertical = {
          preview_height = 0.5,
        },
      }
      opts.defaults.sorting_strategy = "ascending"
      opts.defaults.cycle_layout_list = { "horizontal", "vertical" }
      opts.defaults.prompt_prefix = "   "
      opts.defaults.selection_caret = " "
      opts.defaults.winblend = 0
      opts.defaults.mappings.i = vim.tbl_deep_extend("force", opts.defaults.mappings.i or {}, {
        ["<C-Right>"] = require("telescope.actions.layout").cycle_layout_next,
        ["<C-Left>"] = require("telescope.actions.layout").cycle_layout_prev,
        ["<C-j>"] = require("telescope.actions").move_selection_next,
        ["<C-k>"] = require("telescope.actions").move_selection_previous,
        ["<C-u>"] = require("telescope.actions").preview_scrolling_up,
        ["<C-d>"] = require("telescope.actions").preview_scrolling_down,
        ["<ESC>"] = require("telescope.actions").close,
      })

      LazyVim.on_load("telescope.nvim", function()
        require("telescope").setup({
          extensions = {
            smart_open = {
              cwd_only = true,
              match_algorithm = "fzf",
            },
            -- undo = {
            --   side_by_side = true,
            --   layout_strategy = "vertical",
            --   layout_config = {
            --     preview_height = 0.6,
            --   },
            -- },
          },
        })

        require("telescope").load_extension("smart_open")
        -- require("telescope").load_extension("undo")
      end)
    end,
  },
}
