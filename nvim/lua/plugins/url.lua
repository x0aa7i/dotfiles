return {
  "sontungexpt/url-open",
  cmd = "URLOpenUnderCursor",
  keys = {
    {
      "gx",
      function()
        vim.cmd("URLOpenUnderCursor")
      end,
      desc = "Open URL",
    },
  },
  config = function()
    require("url-open").setup({
      extra_patterns = {
        {
          pattern = '["]([^%s]*)["]:%s*"[^"]*%d[%d%.]*"',
          prefix = "https://www.npmjs.com/package/",
          suffix = "",
          file_patterns = { "package%.json" },
          excluded_file_patterns = nil,
          extra_condition = function(pattern_found)
            return not vim.tbl_contains({ "version", "proxy" }, pattern_found)
          end,
        },
      },
    })
  end,
}
