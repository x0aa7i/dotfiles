-- Only load this configuration in VSCode
if not vim.g.vscode then
  return
end

-- Load LazyVim VSCode extras
require("lazyvim.plugins.extras.vscode")
local vscode = require("vscode-neovim")

vim.notify = vscode.notify
vim.g.clipboard = vim.g.vscode_clipboard

-- Highlight yanked text
vim.cmd([[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=300})
  augroup END
]])

-- Helper functions for keymaps
local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  -- opts.noremap = opts.noremap ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function vscode_action(...)
  local cmds = { ... }
  return function()
    for _, cmd in ipairs(cmds) do
      vscode.action(cmd)
    end
  end
end

-- Editor Navigation
-- map("n", "<tab>", vscode_action("workbench.action.nextEditorInGroup"))
-- map("n", "<S-tab>", vscode_action("workbench.action.previousEditorInGroup"))
map("n", "Q", vscode_action("workbench.action.closeActiveEditor"))
map("n", "<Leader>bo", vscode_action("workbench.action.closeOtherEditors"), { desc = "Close Other Editors" })
map("n", "<Leader>bh", vscode_action("workbench.action.closeEditorsToTheLeft"), { desc = "Close Left Editors" })
map("n", "<Leader>bl", vscode_action("workbench.action.closeEditorsToTheRight"), { desc = "Close Right Editors" })
map("n", "<Leader>bb", vscode_action("workbench.action.openPreviousRecentlyUsedEditor"))

-- Code navigation
map("n", "gy", vscode_action("editor.action.goToTypeDefinition"), { desc = "Go To Type Definition" })
map("n", "gr", vscode_action("editor.action.goToReferences"), { desc = "Go To References" })
map("n", "gi", vscode_action("editor.action.goToImplementation"), { desc = "Go To Implementations" })
map("n", "gl", vscode_action("editor.action.showHover"), { desc = "Show Hover" })

-- Diagnostic Navigation
map("n", "]d", vscode_action("editor.action.marker.next"), { desc = "Next Diagnostic" })
map("n", "[d", vscode_action("editor.action.marker.prev"), { desc = "Prev Diagnostic" })

-- Text Manipulation
map({ "n", "x" }, "<A-d>", '"_d', { desc = "Delete Without Register" })
map({ "n", "x" }, "<A-c>", '"_c', { desc = "Change Without Register" })

map("n", "<C-a>", vscode_action("editor.action.selectAll"), { desc = "Select All" })
map("n", "<cr>", "ciw", { desc = "Change word under cursor" })

map("n", "<leader>o", "m`o<esc>``", { desc = "Insert blank line below" })
map("n", "<leader>O", "m`O<esc>``", { desc = "Insert blank line above" })

-- Code Actions
map("n", "<leader>cr", vscode_action("editor.action.rename"), { desc = "Rename Symbol" })
map("n", "<leader>cf", vscode_action("editor.action.formatDocument"), { desc = "Format Document" })
map("n", "<leader>cc", vscode_action("workbench.action.commentLine"), { desc = "Toggle Comment" })

-- UI Actions
map("n", "<leader>e", vscode_action("workbench.action.toggleSidebarVisibility"), { desc = "Toggle Sidebar" })

-- Search and Navigation
map("n", "<leader>sg", vscode_action("workbench.action.quickTextSearch"), { desc = "Quick Text Search" })
map("n", "<leader>sf", vscode_action("workbench.action.findInFiles"), { desc = "Find in Files" })
map("n", "<leader>ff", vscode_action("workbench.action.quickOpen"), { desc = "Quick Open" })
map("n", "<leader><space>", vscode_action("workbench.action.quickOpen"), { desc = "Quick Open" })

-- Line Navigation
map({ "n", "x" }, "H", "^", { desc = "Move to start of line" })
map({ "n", "x" }, "L", "$", { desc = "Move to end of line" })

-- Git Actions
map("n", "<leader>ghs", vscode_action("git.stageSelectedRanges"), { desc = "Stage Selected Ranges" })
map("n", "<leader>ghr", vscode_action("git.unstageSelectedRanges"), { desc = "Unstage Selected Ranges" })
map("n", "<leader>ghr", vscode_action("git.revertSelectedRanges"), { desc = "Revert Selected Ranges" })

-- Git Navigation
local next_git_change = vscode_action("workbench.action.editor.nextChange", "workbench.action.compareEditor.nextChange")
-- stylua: ignore
local prev_git_change = vscode_action("workbench.action.editor.previousChange", "workbench.action.compareEditor.previousChange")

map("n", "]h", next_git_change, { desc = "Next Git Diff" })
map("n", "[h", prev_git_change, { desc = "Prev Git Diff" })

-- Window Management
map("n", "<leader>wq", vscode_action("workbench.action.closeEditorsInGroup"), { desc = "Close Editors in Group" })
map("n", "<leader>wv", vscode_action("workbench.action.splitEditorRight"), { desc = "Split Editor Right" })
map("n", "<leader>ws", vscode_action("workbench.action.splitEditorDown"), { desc = "Split Editor Down" })
map("n", "<leader>wj", vscode_action("workbench.action.joinEditors"), { desc = "Join Editors" })
map("n", "<leader>wh", vscode_action("workbench.action.moveEditorToNextGroup"), { desc = "Move Editor to Next Group" })
-- stylua: ignore
map( "n", "<leader>wl", vscode_action("workbench.action.moveEditorToPreviousGroup"), { desc = "Move Editor to Previous Group" })
