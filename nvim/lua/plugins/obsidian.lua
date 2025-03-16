local vault_path = "/mnt/buckup/documents/obsidian"

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    enabled = false,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    event = {
      -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
      -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
      ("BufReadPre %s/**.md"):format(vault_path),
      ("BufNewFile %s/**.md"):format(vault_path),
    },
    cmd = { "ObsidianToday", "ObsidianYesterday", "ObsidianTomorrow", "ObsidianNew", "ObsidianSearch" },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>od", "<cmd>ObsidianDailies<CR>", desc = "Daily notes" },
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
      { "<leader>oj", "<cmd>ObsidianToday<CR>", desc = "Today note" },
      { "<leader>ot", "<cmd>ObsidianTemplate<CR>", desc = "Template" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>ObsidianLink<cr>", desc = "Link selection" },
      { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow link under cursor" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search" },
      { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename" },
      { "<leader>of", "<cmd>ObsidianQuickSwitch<cr>", desc = "Find" },
      { "<leader>og", "<cmd>ObsidianTags<cr>", desc = "Tags" },
      { "<leader>ow", "<cmd>ObsidianWorkspace personal<cr>", desc = "Personal workspace" },
      { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open in app" },
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = vault_path,
        },
      },
      completion = {
        nvim_cmp = false,
      },
      ui = {
        enable = false,
      },
      -- see below for full list of options 👇
      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = "Journal/Daily/2025",
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = "%Y-%m-%d",
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = "%B %-d, %Y",
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = "Assets/Templates/nvim/daily.md",
      },

      templates = {
        folder = "Assets/Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        -- A map for custom variables, the key should be the variable and the value a function
        substitutions = {
          ["now"] = function()
            return os.date("%Y-%m-%d %H:%M")
          end,
          ["long-date"] = function()
            return os.date("%A, %B %d %Y")
          end,
        },
      },

      highlight = {
        enable = false,
        additional_vim_regex_highlighting = { "markdown" },
      },

      -- `true` indicates that you don't want obsidian.nvim to manage frontmatter.
      disable_frontmatter = true,

      -- Optional, alternatively you can customize the frontmatter data.
      ---@return table
      note_frontmatter_func = function(note)
        local out = {
          aliases = note.aliases,
          tags = note.tags,
          created = os.date("%Y-%m-%d %H:%M"),
        }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,

      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle check-boxes.
        ["<leader>nc"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true, desc = "Toggle checkbox" },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "obsidian", icon = "" },
      },
    },
  },
}
