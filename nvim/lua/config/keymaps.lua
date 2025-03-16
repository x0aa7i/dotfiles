-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
if vim.g.vscode then -- use vscode keymaps instead
  require("config.vscode")
  return
end

-- Quit
K.map("<C-q>", "<cmd>qa<cr>", { desc = "Quit all" })

-- Better Search navigation
K.map("n", "nzz")
K.map("N", "Nzz")
K.map("*", "*zz")
K.map("#", "#zz")
K.map("g*", "g*zz")
K.map("g#", "g#zz")

-- Press jk fast to enter normal mode
K.map("jk", "<ESC>", { mode = "i" })

-- inset empty blank line above/below
K.map("<C-CR>", "m`o<esc>``", { mode = "n", desc = "Insert new line above" })
K.map("<S-CR>", "m`O<esc>``", { mode = "n", desc = "Insert new line below" })
K.map("<C-CR>", "<esc>m`o<esc>``gi", { mode = "i", desc = "Insert new line above" })
K.map("<S-CR>", "<esc>m`O<esc>``gi", { mode = "i", desc = "Insert new line below" })

K.map("<A-d>", [[m`"yyy"yp``j]], { mode = "n", desc = "Duplicate line" })
K.map("<A-d>", [[<Esc>"yyy"ypgi]], { mode = "i", desc = "Duplicate line" })
K.map("<A-d>", [["yy'>"ypgv]], { mode = "v", desc = "Duplicate selection" })

-- select all
K.map("<C-S-a>", "<esc>ggVG", { mode = { "i", "n", "v" } })

-- Move to start/end of line
K.map("H", "^", { mode = { "n", "x" } })
K.map("L", "$", { mode = { "n", "x" } })

-- Delete word with backspace
K.map("<C-BS>", "<C-w>", { mode = "i" })
K.map("<C-Del>", "<esc>cw", { mode = "i" })

K.map("<CR>", [["xciw]], { mode = "n", desc = "Change inner word" })
K.map("<CR>", [["xc]], { mode = "v", desc = "Change selection" })

K.map("gl", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- Folds
K.map("z1", "<cmd> setlocal foldlevel=0<cr>", { mode = "n", desc = "Fold Level 1" })
K.map("z2", "<cmd> setlocal foldlevel=1<cr>", { mode = "n", desc = "Fold Level 2" })
K.map("z3", "<cmd> setlocal foldlevel=2<cr>", { mode = "n", desc = "Fold Level 3" })
K.map("z4", "<cmd> setlocal foldlevel=3<cr>", { mode = "n", desc = "Fold Level 4" })
K.map("z5", "<cmd> setlocal foldlevel=4<cr>", { mode = "n", desc = "Fold Level 5" })

-- windows
K.map("<leader>wq", "<C-W>c", { desc = "Delete Window", remap = true })
K.map("<leader>ws", "<C-W>s", { desc = "Split Window Below", remap = true })
K.map("<leader>wv", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Buffers
K.map("Q", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })

-- tabs
K.map("<leader><tab>q", "<cmd>tabclose<cr>", { desc = "Close Tab" })
K.map("]<tab>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
K.map("[<tab>", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Comment
K.map("<c-/>", "<Nop>") -- Remove terminal keybind set by lazyvim

K.map("<c-/>", "gcc", { mode = "n", desc = "comment toggle", remap = true })
K.map("<c-/>", "gc", { mode = "v", desc = "comment toggle", remap = true })

K.map("<c-_>", "gcc", { mode = "n", desc = "comment toggle", remap = true })
K.map("<c-_>", "gc", { mode = "v", desc = "comment toggle", remap = true })


-- Terminal
-- stylua: ignore
local terminal = function() Snacks.terminal.toggle() end
K.map("<c-\\>", terminal, { mode = { "n", "t" }, desc = "Terminal (Root Dir)" })

-- Google search
local searching_google_in_visual =
  [[<ESC>gv"gy<ESC>:lua vim.fn.system({'xdg-open', 'https://google.com/search?q=' .. vim.fn.getreg('g')})<CR>]]

K.map("gx", searching_google_in_visual, { mode = "v", silent = true, noremap = true })
