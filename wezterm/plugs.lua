--   ╭─────────────────────────────────────────────────────────╮
--   │                         PLUGINS                         │
--   ╰─────────────────────────────────────────────────────────╯

local function setup(config)
	-- List of plugins to load
	local plugins = {
		"hyperlinks",
		--"plugin_mgr",
		"smart_splits",
		"tabline",
		"workspaces",
	}

	-- Load all plugins
	for _, plugin in ipairs(plugins) do
		require("plugins." .. plugin)(config)
	end
end

return setup
