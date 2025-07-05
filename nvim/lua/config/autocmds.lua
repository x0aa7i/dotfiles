-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

autocmd("BufReadPost", {
  desc = "Disable diagnostic for .env files",
  pattern = { "*.env", ".env.*" },
  callback = function(ev)
    vim.diagnostic.enable(false, { bufnr = ev.buf })
  end,
})

autocmd({ "BufEnter", "BufReadPost" }, {
  desc = "Remove '-' from iskeyword",
  pattern = "*",
  callback = function()
    vim.opt_local.iskeyword:remove("-")
  end,
})

autocmd("BufWritePre", {
  desc = "Remove all trailing whitespace on save",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
  group = augroup("TrimWhiteSpaceGrp", { clear = true }),
})

autocmd("BufWritePre", {
  desc = "Replace smart quotes and apostrophes in Markdown files",
  pattern = { "*.md" },
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/[“”]/"/ge | %s/’/'/ge]])
    vim.fn.setpos(".", save_cursor)
  end,
  group = augroup("MarkdownCleanupGrp", { clear = true }),
})

-- Delete [No Name] buffers
autocmd("BufHidden", {
  callback = function(event)
    if event.file == "" and vim.bo[event.buf].buftype == "" and not vim.bo[event.buf].modified then
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, event.buf, {})
      end)
    end
  end,
})
