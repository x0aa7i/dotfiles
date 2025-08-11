vim.filetype.add({ extension = { mdx = "markdown.mdx" } })
vim.filetype.add({ extension = { svx = "markdown.svx" } })

local vault_path = "/mnt/backup/documents/obsidian"

--Retrieves an LSP client by name
---@param name string
---@return vim.lsp.Client | nil
local function getLSPClient(name)
  return vim.lsp.get_clients({ bufnr = 0, name = name })[1]
end

---Toggles an LSP client by name
---@param name string
---@return nil
local function toggleLSPClient(name)
  local client = getLSPClient(name)
  if client then
    ---@diagnostic disable-next-line: param-type-mismatch
    client.stop(true)
  else
    vim.cmd("LspStart " .. name)
  end
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        -- { "<leader>o", group = "markdown", icon = { icon = "󰍔 ", color = "white" } },
        { "<leader>op", icon = { icon = " ", color = "blue" } }, -- HakonHarnes/img-clip.nvim
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "markdown-oxide", -- PKM markdown lsp
        "markdownlint-cli2", -- markdown linter
        "markdown-toc", -- markdown table of contents
        -- "marksman", -- markdown lsp
        "harper-ls", -- grammar checker
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    keys = {
      -- { "<leader>oj", "<cmd>Today<cr>", desc = "Journal note" }, -- markdown-oxide
    },
    opts = {
      servers = {
        markdown_oxide = {
          enabled = true,
          capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } },
        },
        -- The hover window configuration for the diagnostics is done in
        -- ~/github/dotfiles-latest/neovim/neobean/lua/config/autocmds.lua
        harper_ls = {
          autostart = false,
          enabled = true,
          filetypes = { "markdown" },
          settings = {
            ["harper-ls"] = {
              userDictPath = vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
              codeActions = { forceStable = true },
              linters = {
                -- ToDoHyphen = false,
                -- SpellCheck = true,
                SentenceCapitalization = false,
                Spaces = false,
              },
              isolateEnglish = true,
              markdown = {
                IgnoreLinkTitle = true,
              },
            },
          },
        },
      },
      setup = {
        harper_ls = function()
          Snacks.toggle({
            name = "Grammar Checker",
            get = function()
              return getLSPClient("harper_ls") ~= nil
            end,
            set = function()
              toggleLSPClient("harper_ls")
            end,
          }):map("<leader>uk")
        end,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then
                return true
              end
            end
          end,
        },
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
      },
      formatters_by_ft = {
        ["markdown"] = { "dprint", "markdown-toc" },
        ["mdx"] = { "prettierd", "markdown-toc" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      },
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.stdpath("config") .. "/rules/.markdownlint.json" },
        },
      },
    },
  },
  {
    "bullets-vim/bullets.vim",
    event = "VeryLazy",
    ft = { "markdown", "text", "gitcommit" },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = true,
    version = "*",
    ft = { "markdown", "norg", "org" },
    opts = {
      file_types = { "markdown", "norg", "rmd", "org" },
      latex = { enabled = false, position = "below" },
      code = {
        sign = false,
        width = "block",
        right_pad = 2,
        left_pad = 2,
        min_width = 48,
        position = "right",
        border = "thick",
      },
      heading = {
        sign = false,
        width = "block", -- full, block
        icons = {},
      },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = " " },
        custom = {
          incomplete = {
            raw = "[/]",
            rendered = "󰦖 ",
            highlight = "RenderMarkdownIncomplete",
            scope_highlight = nil,
          },
          canceled = { raw = "[-]", rendered = "󰜺 ", highlight = "RenderMarkdownCanceled", scope_highlight = nil },
          forwarded = { raw = "[>]", rendered = " ", highlight = "RenderMarkdownForwarded", scope_highlight = nil },
          schedule = { raw = "[<]", rendered = " ", highlight = "RenderMarkdownSchedule", scope_highlight = nil },

          info = { raw = "[i]", rendered = " ", highlight = "RenderMarkdownInfo", scope_highlight = nil },
          idea = { raw = "[I]", rendered = " ", highlight = "RenderMarkdownIdea", scope_highlight = nil },
          important = { raw = "[!]", rendered = " ", highlight = "RenderMarkdownImportant", scope_highlight = nil },
          question = { raw = "[?]", rendered = " ", highlight = "RenderMarkdownQuestion", scope_highlight = nil },
          pros = { raw = "[p]", rendered = " ", highlight = "RenderMarkdownPros", scope_highlight = nil },
          cons = { raw = "[c]", rendered = " ", highlight = "RenderMarkdownCons", scope_highlight = nil },

          fire = { raw = "[f]", rendered = " ", highlight = "RenderMarkdownFire", scope_highlight = nil },
          star = { raw = "[*]", rendered = " ", highlight = "RenderMarkdownStar", scope_highlight = nil },
          bookmark = { raw = "[b]", rendered = " ", highlight = "RenderMarkdownBookmark", scope_highlight = nil },
          trend_up = { raw = "[u]", rendered = " ", highlight = "RenderMarkdownTrendUp", scope_highlight = nil },
          trend_down = {
            raw = "[d]",
            rendered = " ",
            highlight = "RenderMarkdownTrendDown",
            scope_highlight = nil,
          },
          win = { raw = "[w]", rendered = " ", highlight = "RenderMarkdownWin", scope_highlight = nil },

          key = { raw = "[k]", rendered = " ", highlight = "RenderMarkdownKey", scope_highlight = nil },
          quote = { raw = '["]', rendered = " ", highlight = "RenderMarkdownQuote", scope_highlight = nil },
          money = { raw = "[S]", rendered = " ", highlight = "RenderMarkdownMoney", scope_highlight = nil },
          location = { raw = "[l]", rendered = " ", highlight = "RenderMarkdownLocation", scope_highlight = nil },
          new = { raw = "[n]", rendered = " ", highlight = "RenderMarkdownNew", scope_highlight = nil },
          progress0 = { raw = "[0]", rendered = " ", highlight = "RenderMarkdownProgress", scope_highlight = nil },
          progress1 = { raw = "[1]", rendered = " ", highlight = "RenderMarkdownProgress", scope_highlight = nil },
          progress2 = { raw = "[2]", rendered = " ", highlight = "RenderMarkdownProgress", scope_highlight = nil },
          progress3 = { raw = "[3]", rendered = " ", highlight = "RenderMarkdownProgress", scope_highlight = nil },
          progress4 = { raw = "[4]", rendered = " ", highlight = "RenderMarkdownProgress", scope_highlight = nil },
        },
      },
      html = {
        -- Turn on / off all HTML rendering.
        enabled = true,
        comment = {
          -- Turn on / off HTML comment concealing.
          conceal = false,
        },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = function()
          return require("render-markdown.state").enabled
        end,
        set = function(enabled)
          local m = require("render-markdown")
          if enabled then
            m.enable()
          else
            m.disable()
          end
        end,
      }):map("<leader>um")
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function()
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      {
        "<leader>oo",
        "<cmd>MarkdownPreviewToggle<cr>",
        ft = "markdown",
        desc = "Open Markdown Preview",
      },
    },
    config = function()
      vim.cmd([[do FileType]])
    end,
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    ft = "markdown",
    keys = {
      { "<leader>op", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
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
  },
  {
    -- toggle lists
    "hamidi-dev/org-list.nvim",
    ft = { "norg", "org", "markdown" },
    event = "VeryLazy",
    dependencies = {
      "tpope/vim-repeat", -- for repeatable actions with '.'
    },
    config = function()
      require("org-list").setup({
        mapping = {
          key = "<leader>ol",
          desc = "Toggle: Cycle through list types",
        },
        checkbox_toggle = {
          enabled = true,
          key = "<leader>ok", -- Change the checkbox toggle key
          desc = "Toggle checkbox state",
          filetypes = { "org", "markdown" }, -- Add more filetypes as needed
        },
      })
    end,
  },
}
