return {
  -- better fold
  "kevinhwang91/nvim-ufo",
  enabled = false,
  event = { "BufRead", "BufNewFile" },
  dependencies = { "kevinhwang91/promise-async" },
  -- stylua: ignore
  keys = {
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    { "zr", function() require("ufo").openFoldsExceptKinds({ 'imports', 'comment' }) end, desc = " Open all folds except comments" },
    { "zm", function() require("ufo").closeAllFolds() end, desc = " Close all folds" },
    { "zk", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek folded lines under cursor" },
    { "z1", function() require("ufo").closeFoldsWith(0) end, desc = "Close L1 Folds", },
    { "z2", function() require("ufo").closeFoldsWith(1) end, desc = "Close L2 Folds" },
    { "z3", function() require("ufo").closeFoldsWith(2) end, desc = "Close L3 Folds" },
    { "z4", function() require("ufo").closeFoldsWith(3) end, desc = "Close L4 Folds" },
  },
  -- Specifies code to run before this plugin is loaded.
  opts = function()
    local handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = (" 󰁂 %d "):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          -- str width returned from truncate() may less than 2nd argument, need padding
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, "MoreMsg" })
      return newVirtText
    end

    return {
      fold_virt_text_handler = handler,
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
      preview = {
        win_config = { winblend = 0 },
      },
    }
  end,
}
