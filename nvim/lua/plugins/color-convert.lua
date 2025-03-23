return {
  {
    "NTBBloodbath/color-converter.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>vv",
        function()
          require("color-converter").cycle()
        end,
        mode = "n",
        desc = "color cycle",
      },
      {
        "<leader>vh",
        function()
          require("color-converter").to_hex()
        end,
        mode = "n",
        desc = "color to hex",
      },
      {
        "<leader>vs",
        function()
          require("color-converter").to_hsl()
        end,
        mode = "n",
        desc = "color to hsl",
      },
      {
        "<leader>vr",
        function()
          require("color-converter").to_rgb()
        end,
        mode = "n",
        desc = "color to rgb",
      },
    },
    opts = {
      lowercase_hex = true,
      hsl_pattern = "hsl([h], [s]%, [l]%)",
      hsla_pattern = "hsl([h], [s]%, [l]%, [a])",
      rgb_pattern = "rgb([r], [g], [b])",
      rgba_pattern = "rgb([r], [g], [b], [a])",
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>v", group = "convert", icon = "" },
      },
    },
  },
}
