-- source: https://gist.github.com/tmerse/dc21ec932860013e56882f23ee9ad8d2

return {
  "nvim-mini/mini.pairs",
  enabled = true,
  event = { "VeryLazy" },
  version = "*",
  opts = {
    -- In which modes mappings from this `config` should be created
    modes = { insert = true, command = true, terminal = true },

    mappings = {
      [")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
      ["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
      ["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },

      ["["] = { action = "open", pair = "[]", neigh_pattern = ".[%s%z%)}%]]", register = { cr = false } },
      ["{"] = { action = "open", pair = "{}", neigh_pattern = ".[%s%z%)}%]]", register = { cr = false } },
      ["("] = { action = "open", pair = "()", neigh_pattern = ".[%s%z%)]", register = { cr = false } },

      -- Single quote: Prevent pairing if either side is a letter
      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
      -- Single quote: Prevent pairing if either side is a letter
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
      -- Backtick: Prevent pairing if either side is a letter
      ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
    },
  },
}
