-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.breakindent = true -- Every wrapped line will continue visually indented
vim.opt.breakindentopt = "list:-1"

vim.opt.pumblend = 0 -- make popup menu transparent, value range [0,100]

-- vim.g.clipboard = {
--   name = "OSC 52",
--   copy = {
--     ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
--     ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
--   },
--   paste = {
--     ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
--     ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
--   },
-- }

vim.opt.listchars:append({
  tab = "▏ ",
  trail = "·",
  nbsp = "␣",
  extends = "…",
  precedes = "…",
})

vim.filetype.add({ pattern = { [".*/tmux.*.conf"] = "tmux" } })
vim.filetype.add({ extension = { vert = "glsl" } })
vim.filetype.add({ extension = { frag = "glsl" } })
vim.filetype.add({ extension = { glsl = "glsl" } })
vim.filetype.add({ extension = { wgsl = "glsl" } })
