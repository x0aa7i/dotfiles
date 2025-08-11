K = {}

local default_map_opts = {
  silent = true,
  remap = false,
}

---@alias Mode "n"|"v"|"i"|"c"|"s"|"o"|"t"|"x"

---@class Opts
---@field desc string|nil Description for the keymap
---@field silent boolean|nil Suppress command output
---@field buffer integer|nil Buffer number (if buffer-local keymap)
---@field remap boolean|nil Allow remapping
---@field nowait boolean|nil Do not wait for a character in a mapping
---@field expr boolean|nil The RHS is an expression
---@field unique boolean|nil Throw an error if mapping already exists

--- Map a key
---@param mode Mode|Mode[] Keymap mode(s)
---@param key string Key to be mapped
---@param cmd string|function Action to be taken
---@param options? Opts Options for the keymap
---
---@return nil
function K.map(mode, key, cmd, options)
  local opts = vim.tbl_extend("force", default_map_opts, options or {})
  vim.keymap.set(mode, key, cmd, opts)
end
