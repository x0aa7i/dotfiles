K = {}

local default_map_opts = {
  mode = "n",
  silent = true,
  noremap = true,
}

---@alias Mode "n"|"v"|"i"|"c"|"s"|"o"|"t"|"x"

---@class Opts
---@field mode Mode|Mode[]|nil Keymap mode(s)
---@field desc string|nil Description for the keymap
---@field silent boolean|nil Suppress command output
---@field noremap boolean|nil Do not allow remapping
---@field buffer integer|nil Buffer number (if buffer-local keymap)
---@field remap boolean|nil Allow remapping

--- Map a key
---@param key string Key to be mapped
---@param cmd string|function Action to be taken
---@param options? Opts Options for the keymap
---
---@return nil
function K.map(key, cmd, options)
  local opts = vim.tbl_extend("force", default_map_opts, options or {})

  local mode = opts.mode
  opts.mode = nil

  vim.keymap.set(mode, key, cmd, opts)
end
