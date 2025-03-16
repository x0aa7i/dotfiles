return {
  "hrsh7th/nvim-cmp",
  enabled = false,
  dependencies = {
    { "octaltree/cmp-look", ft = { "markdown", "text" } }, -- dictionary
    "xzbdmw/colorful-menu.nvim",
  },
  keys = {
    {
      "<Tab>",
      function()
        local supermaven = require("supermaven-nvim.completion_preview")

        if vim.snippet.active({ direction = 1 }) then
          return "<cmd>lua vim.snippet.jump(1)<cr>"
        elseif supermaven.has_suggestion() then
          return "<cmd>lua require('supermaven-nvim.completion_preview').on_accept_suggestion()<cr>"
        end

        return "<Tab>"
      end,
      expr = true,
      silent = true,
      mode = { "i", "s" },
    },
  },
  opts = function(_, opts)
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local cmp = require("cmp")

    opts.experimental = opts.experimental or {}
    opts.experimental.ghost_text = false

    opts.formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, item)
        local highlights_info = require("colorful-menu").cmp_highlights(entry)
        if highlights_info ~= nil then
          item.abbr_hl_group = highlights_info.highlights
          item.abbr = highlights_info.text
        end

        local color = entry.completion_item.documentation
        if color and type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
          local hl = "hex-" .. color:sub(2)

          if #vim.api.nvim_get_hl(0, { name = hl }) == 0 then
            vim.api.nvim_set_hl(0, hl, { fg = color })
          end

          item.kind = ""
          item.kind_hl_group = hl
        else
          local icons = LazyVim.config.icons.kinds

          if icons[item.kind] then
            -- item.kind = icons[item.kind] .. item.kind
            item.kind = icons[item.kind]:gsub("%s+$", "") .. " "
          end
        end

        -- item.menu = item.kind

        local widths = {
          abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 50,
          menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
        }

        for key, width in pairs(widths) do
          if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
            item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
          end
        end

        return item
      end,
    }

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<C-j>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-k>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { "i", "s" }),
    })

    opts.sources = cmp.config.sources({
      { name = "codeium", max_item_count = 3 },
      { name = "nvim_lsp" },
      { name = "buffer", max_item_count = 3, keyword_length = 5 },
      { name = "path", max_item_count = 3 },
      { name = "snippets" },
    }, {
      { name = "buffer" },
      { name = "look", keyword_length = 3 },
    })
  end,
}
