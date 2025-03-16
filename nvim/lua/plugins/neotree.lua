return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.close_if_last_window = true
    opts.hide_root_node = true
    opts.retain_hidden_root_indent = true

    opts.window = opts.window or {}
    opts.window.position = "left"

    opts.window.mappings = opts.window.mappings or {}
    -- opts.window.mappings["<space>"] = {
    --   "toggle_node",
    --   nowait = true, -- disable `nowait` if you have existing combos starting with this char that you want to use
    -- }
    opts.window.mappings["<tab>"] = "next_source"
    opts.window.mappings["<s-tab>"] = "prev_source"

    -- Sources
    opts.source_selector = {
      winbar = true,
      show_scrolled_off_parent_node = true,
      sources = {
        { source = "filesystem", display_name = "  Files" }, --     
        { source = "git_status", display_name = " 󰊢 Git" }, -- 󰊢    
        { source = "buffers", display_name = "  Buffers" }, --   
      },
    }

    -- Show hidden files
    opts.filesystem = opts.filesystem or {}
    opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}
    opts.filesystem.filtered_items.hide_dotfiles = false
    opts.filesystem.filtered_items.hide_gitignored = false
    opts.filesystem.filtered_items.hide_hidden = false

    -- Default component configs
    opts.default_component_configs = opts.default_component_configs or {}

    opts.default_component_configs.name = opts.default_component_configs.name or {}
    opts.default_component_configs.name.highlight_opened_files = true

    opts.default_component_configs.modified = opts.default_component_configs.modified or {}
    opts.default_component_configs.modified.symbol = ""
    opts.default_component_configs.modified.highlight = "NeoTreeModified"

    opts.default_component_configs.git_status = opts.default_component_configs.git_status or {}
    opts.default_component_configs.git_status.symbols = opts.default_component_configs.git_status.symbols or {}

    -- Change git status icons (default:  ✚    󰊢        )
    opts.default_component_configs.git_status.symbols = {
      added = "", -- or  "✚", but this is redundant info if you use git_status_colors on the name
      modified = "", -- or 󰧞 "", but this is redundant info if you use git_status_colors on the name
      deleted = "", -- this can only be used in the git_status source
      renamed = "", -- this can only be used in the git_status source
      untracked = "?", -- 
      ignored = "",
      unstaged = "",
      staged = "",
      conflict = "",
    }

    opts.default_component_configs.filesystem = opts.default_component_configs.filesystem or {}
    opts.default_component_configs.filesystem.commands = opts.default_component_configs.filesystem.commands or {}

    local inputs = require("neo-tree.ui.inputs")
    local cmds = require("neo-tree.sources.filesystem.commands")

    -- over write default 'delete' command to 'trash'.
    opts.default_component_configs.filesystem.commands.delete = function(state)
      local utils = require("neo-tree.utils")

      local node = state.tree:get_node()
      if node.type == "message" then
        return
      end
      local _, name = utils.split_path(node.path)
      local msg = string.format("Are you sure you want to trash '%s'?", name)
      inputs.confirm(msg, function(confirmed)
        if not confirmed then
          return
        end
        vim.api.nvim_command("silent !trash -f " .. node.path)
        cmds.refresh(state)
      end)
    end

    -- over write default 'delete_visual' command to 'trash' x n.
    opts.default_component_configs.filesystem.commands.delete_visual = function(state, selected_nodes)
      local paths_to_trash = {}
      for _, node in ipairs(selected_nodes) do
        if node.type ~= "message" then
          table.insert(paths_to_trash, node.path)
        end
      end
      local msg = "Are you sure you want to trash " .. #paths_to_trash .. " items?"
      inputs.confirm(msg, function(confirmed)
        if not confirmed then
          return
        end
        for _, path in ipairs(paths_to_trash) do
          vim.api.nvim_command("silent !trash -f " .. path)
        end
        cmds.refresh(state)
      end)
    end
  end,
}
