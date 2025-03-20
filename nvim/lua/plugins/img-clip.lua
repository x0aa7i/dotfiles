local vault_path = "/mnt/backup/documents/obsidian"

return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  ft = "markdown",
  opts = {
    default = {
      dir_path = "images",
      process_cmd = "convert - -quality 80 -",
      show_dir_path_in_prompt = true,
    },
    dirs = {
      [vault_path] = {
        file_name = function()
          local time = "_%Y-%m-%d-%H-%M-%S"
          return vim.fn.expand("%:t:r") .. time
        end,
        dir_path = function()
          return "Assets/Attachments"
        end,
      },
    },
  },
  keys = {
    { "<leader>m", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
  },
}
