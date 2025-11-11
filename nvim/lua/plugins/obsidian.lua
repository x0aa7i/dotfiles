local vault_path = "/mnt/backup/documents/obsidian"

return {
  {
    "obsidian-nvim/obsidian.nvim",
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
    keys = {
      { "<leader>od", "<cmd>Obsidian dailies<CR>", desc = "Daily notes" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>oN", "<cmd>Obsidian new_from_template<CR>", desc = "New Templated Note" },
      { "<leader>oj", "<cmd>Obsidian today<CR>", desc = "Today note" },
      { "<leader>ot", "<cmd>Obsidian template<CR>", desc = "Template" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>Obsidian link<CR>", desc = "New Link", mode = "v" },
      { "<leader>ol", "<cmd>Obsidian links<CR>", desc = "List Links" },
      { "<leader>oL", "<cmd>Obsidian link_new<CR>", desc = "New Link & File", mode = "v" },
      { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Follow link under cursor" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename" },
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find" },
      { "<leader>og", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>ow", "<cmd>Obsidian workspace personal<cr>", desc = "Personal workspace" },
      { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian app" },
      { "<leader>oh", "<cmd>Obsidian check<CR>", desc = "Check Health" },
      { "<leader>oH", "<cmd>Obsidian debug<CR>", desc = "Debug Info" },
      -- { "<leader>op", "<cmd>Obsidian pasteImg<CR>", desc = "Paste Image" },
      -- { "<leader>og", "<cmd>Obsidian search<CR>", desc = "Grep" },

      -- { "<leader>ot", "<cmd>Obsidian tags<CR>", desc = "Search Tags" },
      { "<leader>ow", "<cmd>Obsidian workspace<CR>", desc = "Change Workspace" },
      { "<leader>o<space>", "<cmd>Obsidian quick_switch<CR>", desc = "Find Note" },
    },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      workspaces = {
        {
          name = "personal",
          path = vault_path,
        },
      },
      completion = { -- handled by markdown-oxide instead
        nvim_cmp = false,
        blink = false,
        min_chars = 2, -- Trigger completion at 2 chars.
      },

      ui = {
        enable = false,
      },

      -- see below for full list of options 👇
      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = "Journal/Daily",
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = "%Y/%Y-%m-%d",
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
      -- disable_frontmatter = function()
      --   local filepath = vim.fn.expand("%:p")
      --   local directories = { "Assets/Templates" }
      --
      --   for _, directory in ipairs(directories) do
      --     if filepath:find(directory, 1, true) ~= nil then
      --       return true
      --     end
      --   end
      --   return false
      -- end,
      disable_frontmatter = true,

      -- Either 'wiki' or 'markdown'.
      preferred_link_style = "wiki",

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

        out.modified = os.date("%Y-%m-%d %H:%M")

        return out
      end,

      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.pick'.
        name = "snacks.pick",
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        note_mappings = {
          -- Create a new note from your query.
          new = "<C-x>",
          -- Insert a link to the selected note.
          insert_link = "<C-l>",
        },
        tag_mappings = {
          -- Add tag(s) to current note.
          tag_note = "<C-x>",
          -- Insert a tag at the current location.
          insert_tag = "<C-l>",
        },
      },

      footer = {
        enabled = true,
        format = "{{backlinks}} backlinks  {{properties}} properties", -- works like the template system
        -- hl_group = "@property", -- Use another hl group
      },

      statusline = {
        enabled = false,
        format = "{{properties}} props {{backlinks}} backlinks",
      },

      callbacks = {
        enter_note = function(_, note)
          vim.keymap.del("n", "<CR>", { buffer = note.bufnr })

          vim.keymap.set(
            "n",
            "gd",
            "<cmd>Obsidian follow_link<CR>",
            { noremap = true, silent = true, buffer = note.bufnr, desc = "Follow link" }
          )
        end,
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
