-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable diagnostic for .env files
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*.env", ".env.*" },
  desc = "Disable diagnostic for .env files",
  callback = function(ev)
    vim.diagnostic.enable(false, { bufnr = ev.buf })
  end,
})

-- Remove '-' from iskeyword
vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
  pattern = "*",
  callback = function()
    vim.opt_local.iskeyword:remove("-")
  end,
})

-- Trim whitespaces
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("trim_whitespaces", { clear = true }),
  pattern = { "*" },
  desc = "Trim trailing whitespaces",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Replace curly single quotes with straight single quotes in Markdown files
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("replace_curly_single_quotes", { clear = true }),
  pattern = { "*.md", "*.markdown" },
  desc = "Replace curly single quotes in markdown files",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[silent! %s/’/'/ge]])
    vim.fn.setpos(".", save_cursor)
  end,
})
