return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "catppuccin/nvim",
    enabled = false,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    -- enabled = false,
    opts = function(_, opts)
      opts.style = "night"
      opts.on_colors = function(colors)
        -- colors.bg_dark = "#101317"
        -- colors.bg = "#16161e"
        -- colors.bg_highlight = "#212231"
        colors.bg_light = "#2f3246"
        -- colors.terminal_black = "#414868"
        -- colors.bg_visual = "#2a2d3f"
        colors.fg = "#a9b1d6"
        colors.red = "#f7768e"
        colors.red1 = "#db4b4b"
        colors.green = "#22d0a2"
        colors.magenta = "#9381ff"
        colors.border_highlight = colors.magenta
      end
      opts.on_highlights = function(H, C)
        H.NeoTreeTitleBar = { fg = C.bg_dark, bg = C.magenta }
        H.NeoTreeFloatBorder = { fg = C.magenta, bg = C.bg_dark }
        H.NeoTreeGitUntracked = { fg = C.green, bold = true }

        H.IlluminatedWordRead = { bg = C.bg_light }
        H.IlluminatedWordText = { bg = C.bg_light }
        H.IlluminatedWordWrite = { bg = C.bg_light }
        H.illuminatedCurWord = { bg = C.bg_light }
        H.illuminatedWord = { bg = C.bg_light }

        H.LspReferenceText = { bg = C.bg_light }
        H.LspReferenceRead = { bg = C.bg_light }
        H.LspReferenceWrite = { bg = C.bg_light }

        H.CursorLine = { bg = "#212231" }
        H.CursorLineNr = { fg = C.magenta }
        H.IblIndent = { fg = C.bg_light } -- indent guide
        H.SnacksIndent = { fg = C.bg_light } -- indent guide
        H.SatelliteBar = { bg = C.terminal_black } -- scrollbar

        H.RenderMarkdownDash = { fg = C.terminal_black }

        -- Custom checkbox highlights
        H.RenderMarkdownIncomplete = { fg = C.yellow } -- Incomplete tasks
        H.RenderMarkdownCanceled = { fg = C.red } -- Canceled tasks
        H.RenderMarkdownForwarded = { fg = C.blue } -- Forwarded tasks
        H.RenderMarkdownSchedule = { fg = C.magenta } -- Scheduled tasks

        H.RenderMarkdownInfo = { fg = C.cyan } -- Info
        H.RenderMarkdownIdea = { fg = C.yelow } -- Idea
        H.RenderMarkdownImportant = { fg = C.red } -- Important
        H.RenderMarkdownQuestion = { fg = C.yellow } -- Question
        H.RenderMarkdownPros = { fg = C.green } -- Pros
        H.RenderMarkdownCons = { fg = C.red } -- Cons

        H.RenderMarkdownFire = { fg = C.orange } -- Fire
        H.RenderMarkdownStar = { fg = C.yellow } -- Star
        H.RenderMarkdownBookmark = { fg = C.purple } -- Bookmark
        H.RenderMarkdownTrendUp = { fg = C.green } -- Trend Up
        H.RenderMarkdownTrendDown = { fg = C.red } -- Trend Down
        H.RenderMarkdownWin = { fg = C.green } -- Win

        H.RenderMarkdownKey = { fg = C.yellow } -- Key
        H.RenderMarkdownQuote = { fg = C.cyan } -- Quote
        H.RenderMarkdownMoney = { fg = C.green } -- Money
        H.RenderMarkdownLocation = { fg = C.blue } -- Location
        H.RenderMarkdownNew = { fg = C.green } -- New
        H.RenderMarkdownProgress = { fg = C.green } -- Progress

        -- darker bg_float variants
        local bg_float2 = "#14151f"
        local bg_float3 = "#0e0e14"

        -- Telescope
        H.TelescopeNormal = { fg = C.fg, bg = bg_float2 }
        H.TelescopeTitle = { fg = bg_float2, bg = C.blue }
        H.TelescopeBorder = { fg = bg_float2, bg = bg_float2 }
        H.TelescopePromptNormal = { fg = C.fg, bg = C.bg_float }
        H.TelescopePromptTitle = { fg = C.bg_float, bg = C.orange }
        H.TelescopePromptBorder = { fg = C.bg_float, bg = C.bg_float }
        H.TelescopePreviewNormal = { fg = C.fg, bg = bg_float3 }
        H.TelescopePreviewBorder = { fg = bg_float3, bg = bg_float3 }

        -- Snacks.picker
        H.SnacksPicker = { fg = C.fg, bg = bg_float2 }
        H.SnacksPickerTitle = { fg = bg_float2, bg = C.blue }
        H.SnacksPickerBorder = { fg = bg_float2, bg = bg_float2 }
        H.SnacksPickerInput = { fg = C.fg, bg = C.bg_float }
        H.SnacksPickerInputTitle = { fg = C.bg_float, bg = C.orange }
        H.SnacksPickerInputBorder = { fg = C.bg_float, bg = C.bg_float }
        H.SnacksPickerPreview = { fg = C.fg, bg = bg_float3 }
        H.SnacksPickerPreviewBorder = { fg = bg_float3, bg = bg_float3 }

        -- Folds
        H.Folded = { fg = C.blue, bg = C.bg_light }

        -- Treesitter
        H.TreesitterContext = { bg = "#212231" }
        H.TreesitterContextLineNumber = { fg = C.terminal_black, bg = "#212231" }
      end
    end,
  },
}
