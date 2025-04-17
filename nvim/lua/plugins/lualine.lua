-- functions taken from https://github.com/mcauley-penney/nvim/blob/main/lua/ui/statusline.lua
local function get_vlinecount_str()
  local raw_count = vim.fn.line(".") - vim.fn.line("v")
  raw_count = raw_count < 0 and raw_count - 1 or raw_count + 1
  return math.abs(raw_count)
end

local hl_str = function(hl, str)
  return "%#" .. hl .. "#" .. str .. "%*"
end

local function text_count()
  local visual_mode = vim.fn.mode():find("[Vv]")
  local wc = vim.fn.wordcount()
  local prefix = visual_mode and "󱎸 " or "󰦨 "
  local filetypes = {
    latex = true,
    tex = true,
    text = true,
    markdown = true,
    vimwiki = true,
  }

  local linecount = visual_mode and get_vlinecount_str() or vim.api.nvim_buf_line_count(0)

  if not filetypes[vim.bo.filetype] or not wc then
    return table.concat({ prefix, linecount })
  end

  local lines = table.concat({ prefix, linecount, hl_str("Comment", " lines") })
  local words = table.concat({ " ", wc.visual_words or wc.words, hl_str("Comment", " words") })
  local chars = visual_mode and table.concat({ " ", wc.visual_chars, hl_str("Comment", " chars") }) or ""

  return table.concat({
    lines,
    words,
    chars,
  })
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  init = function()
    -- Show the current document symbols location from Trouble in lualine
    vim.g.trouble_lualine = false
  end,
  opts = function(_, opts)
    opts.options.component_separators = ""
    opts.options.globalstatus = true

    opts.sections.lualine_a = {
      {
        "mode",
        icon = { "" }, --  
        fmt = function(str)
          return str:sub(1, 3)
        end,
      },
    }

    opts.sections.lualine_b = {
      {
        "branch",
        icon = "",
        cond = function()
          -- only if not on main or master
          local branch = require("lualine.components.branch.git_branch").get_branch()
          return branch ~= "main" and branch ~= "master"
        end,
      },
      { "grapple" },
    }

    table.insert(opts.sections.lualine_c, { "filesize", color = { fg = "#737aa2" }, icon = "" })
    table.insert(opts.sections.lualine_c, { "lsp_status", color = { fg = "#737aa2" } })

    table.remove(opts.sections.lualine_x, 3) -- remove noice status mode https://www.lazyvim.org/plugins/ui#lualinenvim
    table.insert(opts.sections.lualine_x, 1, { text_count, color = { fg = "#a9b1d6" } })

    opts.sections.lualine_y = {}
    opts.sections.lualine_z = {
      { "location", padding = { left = 1, right = 1 } },
    }
  end,
}
