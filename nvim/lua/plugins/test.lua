return {
  "nvim-neotest/neotest",
  enabled = false,
  dependencies = {
    "thenbe/neotest-playwright",
    "marilari88/neotest-vitest",
  },
  opts = {
    adapters = {
      -- ["neotest-playwright"] = {},
      ["neotest-vitest"] = {},
    },
    output_panel = {
      open = "botright vsplit",
    },
    quickfix = {
      open = false,
    },
  },
}
