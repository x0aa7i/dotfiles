return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.presets = opts.presets or {}
    opts.presets.lsp_doc_border = true -- add a border to hover docs and signature help

    vim.list_extend(opts.routes, {
      {
        -- Disable messages
        opts = { skip = true },
        filter = {
          any = {
            { event = "msg_show", find = "%d+ lines, %d+ bytes" },
            { event = "msg_show", find = "%d+L, %d+B" },
            { event = "msg_show", find = "^Hunk %d+ of %d" },
            { event = "msg_show", find = "%d+ change" },
            -- { event = "msg_show", find = "%d+ line" },
            { event = "msg_show", find = "%d+ fewer line" },
            { event = "msg_show", find = "%d+ more line" },
            { event = "msg_show", find = "^Error in decoration provider" }, -- tree-sitter highlight errors
            { event = "notify", find = "No information available" }, -- Hover doc
          },
        },
      },
      {
        -- Mini view
        view = "mini",
        filter = {
          any = {
            { event = "msg_show", find = "%d+B written$" },
            { event = "msg_show", find = "%-%-No lines in buffer%-%-" },
            { event = "msg_show", find = "No more valid diagnostics to move to" },
            { event = "msg_show", find = "^%[nvim%-treesitter%]" },
            { event = "notify", find = "All parsers are up%-to%-date" },
          },
        },
      },
    })
  end,
}
