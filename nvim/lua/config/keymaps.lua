-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
if vim.g.vscode then -- use vscode keymaps instead
  require("config.vscode")
  return
end

-- Quit
K.map("n", "<C-q>", "<cmd>qa<cr>", { desc = "Quit all" })

-- Better Search navigation
K.map("n", "n", "nzz")
K.map("n", "N", "Nzz")
K.map("n", "*", "*zz")
K.map("n", "#", "#zz")
K.map("n", "g*", "g*zz")
K.map("n", "g#", "g#zz")

-- Press jk fast to enter normal mode
K.map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

K.map("n", "<A-d>", [[m`"yyy"yp``j]], { desc = "Duplicate line" })
K.map("i", "<A-d>", [[<Esc>"yyy"ypgi]], { desc = "Duplicate line" })
K.map("v", "<A-d>", [["yy'>"ypgv]], { desc = "Duplicate selection" })

-- select all
K.map({ "i", "n", "v" }, "<C-S-a>", "<esc>ggVG")

-- paste system clipboard
K.map("i", "<C-v>", "<C-r>+", { desc = "Paste" })

-- Move to start/end of line
K.map({ "n", "x" }, "H", "^")
K.map({ "n", "x" }, "L", "$")

-- Delete word with backspace
K.map("i", "<C-BS>", "<C-w>")
K.map("i", "<C-Del>", [[<esc>"xcw]])

K.map("n", "<CR>", [["xciw]], { desc = "Change inner word" })
K.map("v", "<CR>", [["xc]], { desc = "Change selection" })

-- Diagnostics
K.map("n", "gl", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- join lines and maintain cursor position
local join_lines = function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd([[normal! J]])
  vim.api.nvim_win_set_cursor(0, pos)
end

K.map("n", "J", join_lines, { desc = "Join lines" })

-- Folds
K.map("n", "z1", "<cmd> setlocal foldlevel=0<cr>", { desc = "Fold Level 1" })
K.map("n", "z2", "<cmd> setlocal foldlevel=1<cr>", { desc = "Fold Level 2" })
K.map("n", "z3", "<cmd> setlocal foldlevel=2<cr>", { desc = "Fold Level 3" })
K.map("n", "z4", "<cmd> setlocal foldlevel=3<cr>", { desc = "Fold Level 4" })
K.map("n", "z5", "<cmd> setlocal foldlevel=4<cr>", { desc = "Fold Level 5" })

-- windows
K.map("n", "<leader>wq", "<C-W>c", { desc = "Delete Window", remap = true })
K.map("n", "<leader>ws", "<C-W>s", { desc = "Split Window Below", remap = true })
K.map("n", "<leader>wv", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Buffers
K.map("n", "Q", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

-- tabs
K.map("n", "<leader><tab>q", "<cmd>tabclose<cr>", { desc = "Close Tab" })
K.map("n", "]<tab>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
K.map("n", "[<tab>", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Comment
K.map("n", "<c-/>", "<Nop>") -- Remove terminal keybind set by lazyvim

K.map("n", "<c-/>", "gcc", { desc = "comment toggle", remap = true })
K.map("v", "<c-/>", "gc", { desc = "comment toggle", remap = true })

K.map("n", "<c-_>", "gcc", { desc = "comment toggle", remap = true })
K.map("v", "<c-_>", "gc", { desc = "comment toggle", remap = true })

-- Copy file path to clipboard
local copy_file_path_to_clipboard = function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path .. " to clipboard")
end
K.map("n", "<leader>cp", copy_file_path_to_clipboard, { desc = "Copy file path to clipboard" })

-- Terminal
-- stylua: ignore
local terminal = function() Snacks.terminal.toggle() end
K.map({ "n", "t" }, "<c-\\>", terminal, { desc = "Terminal (Root Dir)" })

-- Google search
local searching_google_in_visual =
  [[<ESC>gv"gy<ESC>:lua vim.fn.system({'xdg-open', 'https://google.com/search?q=' .. vim.fn.getreg('g')})<CR>]]

K.map("v", "gx", searching_google_in_visual, { silent = true, noremap = true })
