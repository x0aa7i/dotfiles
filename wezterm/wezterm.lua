local wezterm = require("wezterm")
local config = wezterm.config_builder()

local opts = {}

--- Merges the contents of a Lua file into the opts table.
--- @param path string string The full path to the Lua file.
local function merge_into_opts(path)
	for k, v in pairs(require(path)) do
		opts[k] = v
	end
end

local modules = {
	"config.colors",
	"config.options",
	"config.keymaps",
	"config.startup",
	-- "config.tab",
}

for _, mod in ipairs(modules) do
	merge_into_opts(mod)
end

-- Apply config
for k, v in pairs(opts) do
	config[k] = v
end

-- Load plugins
require("plugs")(config)

return config
