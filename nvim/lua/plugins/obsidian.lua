local vault_path = "/mnt/backup/documents/obsidian"

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "folke/which-key.nvim",
        optional = true,
        opts = {
          spec = {
            { "<leader>o", group = "obsidian", icon = "" },
          },
        },
      },
    },
    event = {
      ("BufReadPre %s/**.md"):format(vault_path),
      ("BufNewFile %s/**.md"):format(vault_path),
    },
    cmd = { "Obsidian" },
    keys = {
      { "<leader>o<space>", "<cmd>Obsidian quick_switch<CR>", desc = "Find Note" },
      { "<leader>of", "<cmd>Obsidian quick_switch<CR>", desc = "Find Note" },
      { "<leader>on", "<cmd>Obsidian new<CR>", desc = "New Note" },
      { "<leader>oN", "<cmd>Obsidian new_from_template<CR>", desc = "New Templated Note" },
      { "<leader>ou", "<cmd>Obsidian unique_note<CR>", desc = "New Unique Note" },
      { "<leader>oj", "<cmd>Obsidian today<CR>", desc = "Today Note" },
      { "<leader>oy", "<cmd>Obsidian yesterday<CR>", desc = "Yesterday Note" },
      { "<leader>ot", "<cmd>Obsidian tomorrow<CR>", desc = "Tomorrow Note" },
      { "<leader>od", "<cmd>Obsidian dailies<CR>", desc = "Daily Notes Picker" },
      { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Search Vault (Grep)" },
      { "<leader>oi", "<cmd>Obsidian template<CR>", desc = "Insert Template" },
      { "<leader>oT", "<cmd>Obsidian toc<CR>", desc = "Table of Contents" },
      { "<leader>ob", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks" },
      { "<leader>oB", "<cmd>Obsidian bookmarks<CR>", desc = "Bookmarks" },
      { "<leader>og", "<cmd>Obsidian tags<CR>", desc = "Tags" },
      { "<leader>ol", "<cmd>Obsidian links<CR>", desc = "List Links" },
      { "<leader>ol", "<cmd>Obsidian link<CR>", desc = "Link Selection", mode = "v" },
      { "<leader>oL", "<cmd>Obsidian link_new<CR>", desc = "New Link & Note", mode = "v" },
      { "<leader>oe", "<cmd>Obsidian extract_note<CR>", desc = "Extract Note", mode = "v" },
      { "<leader>op", "<cmd>Obsidian paste_img<CR>", desc = "Paste Image" },
      { "<leader>or", "<cmd>Obsidian rename<CR>", desc = "Rename Note" },
      { "<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", desc = "Toggle Checkbox" },
      { "<leader>ow", "<cmd>Obsidian workspace<CR>", desc = "Switch Workspace" },
      { "<leader>oo", "<cmd>Obsidian open<CR>", desc = "Open in Obsidian App" },
      { "<leader>oh", "<cmd>Obsidian help<CR>", desc = "Obsidian Help" },
      { "<leader>oH", "<cmd>Obsidian check<CR>", desc = "Check Health" },
    },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "personal",
          path = vault_path,
        },
      },
      new_notes_location = "current_dir",
      note_id_func = function(title, dir)
        return require("obsidian.builtin").title_id(title, dir)
      end,
      completion = {
        min_chars = 2,
        match_case = true,
        create_new = true,
      },
      link = {
        style = "wiki",
        format = "shortest",
      },
      daily_notes = {
        folder = "10-journal/daily",
        date_format = "YYYY/MM/YYYY-MM-DD-dddd",
        alias_format = "%B %-d, %Y",
        template = "60-system/templates/nvim/daily.md",
        default_tags = { "daily-notes" },
        workdays_only = true,
      },
      templates = {
        folder = "60-system/templates",
        date_format = "YYYY-MM-DD",
        time_format = "HH:mm",
        substitutions = {
          ["now"] = function()
            return os.date("%Y-%m-%d %H:%M")
          end,
          ["long-date"] = function()
            return os.date("%A, %B %d %Y")
          end,
          ["cursor"] = function()
            return "{{cursor}}"
          end,
        },
      },
      attachments = {
        folder = "60-system/attachments",
        img_name_func = function()
          return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
        end,
        confirm_img_paste = true,
      },
      picker = {
        name = "snacks.picker",
        note_mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
        tag_mappings = {
          tag_note = "<C-x>",
          insert_tag = "<C-l>",
        },
      },
      frontmatter = {
        enabled = function(fname)
          -- Disable frontmatter for template files
          if fname and fname:find("60%-system/templates") then
            return false
          end
          return true
        end,
        func = function(note)
          local out = {
            aliases = note.aliases,
            tags = note.tags,
            created = os.date("%Y-%m-%d %H:%M"),
          }

          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end

          out.modified = os.date("%Y-%m-%d %H:%M")
          return out
        end,
        sort = { "id", "aliases", "tags", "created", "modified" },
      },
      search = {
        sort_by = "modified",
        sort_reversed = true,
        max_lines = 1000,
      },
      checkbox = {
        enabled = true,
        create_new = true,
        order = { " ", "~", "!", ">", "x" },
      },
      footer = {
        enabled = true,
        format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words",
      },
      ui = {
        enable = false, -- Handled by render-markdown.nvim
      },
      callbacks = {
        enter_note = function(note)
          vim.keymap.set(
            "n",
            "gd",
            "<cmd>Obsidian follow_link<CR>",
            { noremap = true, silent = true, buffer = note.bufnr, desc = "Follow link" }
          )

          -- Handle template cursor positioning (e.g. {{cursor}}, <% tp.file.cursor() %>, or #l)
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(note.bufnr) then
              return
            end
            local lines = vim.api.nvim_buf_get_lines(note.bufnr, 0, -1, false)
            for i, line in ipairs(lines) do
              local s, e = line:find("{{cursor}}", 1, true)
              if not s then
                s, e = line:find("<%%%s*tp%.file%.cursor%(.-%)%s*%%>")
              end
              if not s then
                s, e = line:find("%s*#l$")
              end

              if s then
                local new_line = line:sub(1, s - 1) .. line:sub(e + 1)
                if new_line:match("^%s*[%-%*]%s*%[[^%]]%]$") then
                  new_line = new_line .. " "
                end
                vim.api.nvim_buf_set_lines(note.bufnr, i - 1, i, false, { new_line })
                local target_col = math.max(0, #new_line)
                pcall(vim.api.nvim_win_set_cursor, 0, { i, target_col })
                break
              end
            end
          end)
        end,
      },
    },
  },
}
