local wezterm = require("wezterm")

local function setup(config)
	-- Load Smart-Splits plugin
	local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

	-- Apply Smart-Splits configuration
	smart_splits.apply_to_config(config, {
		-- directional keys to use in order of: left, down, up, right
		direction_keys = {
			move = { "h", "j", "k", "l" }, -- Move with CTRL+H, CTRL+J, CTRL+K, CTRL+L
			resize = { "h", "j", "k", "l" }, -- Resize with ALT+h, ALT+j, ALT+k, ALT+l
		},
		-- modifier keys to combine with direction_keys
		modifiers = {
			move = "CTRL", -- modifier to use for pane movement
			resize = "CTRL|SHIFT", -- modifier to use for pane resize
		},
	})
end

return setup
