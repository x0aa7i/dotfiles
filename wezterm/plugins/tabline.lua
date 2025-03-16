local wezterm = require("wezterm")

local utils = require("utils")
-- local funcs = require("funcs")

-- local colors = require("themes.tokyonight")

local function setup(config)
	local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
	local colors = wezterm.color.load_scheme(config.color_scheme_dirs[1] .. "/" .. config.color_scheme .. ".toml")

	config.use_fancy_tab_bar = false
	config.show_new_tab_button_in_tab_bar = false
	config.tab_bar_at_bottom = false
	config.tab_max_width = 64
	config.window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
	-- conf.colors = {
	-- 	tab_bar = {
	-- background = "#292e42",
	-- inactive_tab_edge = "#292e42",
	-- 	},
	-- }
	config.status_update_interval = 500

	tabline.setup({
		options = {
			icons_enabled = true,
			-- theme = "Catppuccin Mocha",
			section_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
			component_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thin,
				right = wezterm.nerdfonts.ple_left_half_circle_thin,
			},
			tab_separators = {
				left = wezterm.nerdfonts.ple_right_half_circle_thick,
				right = wezterm.nerdfonts.ple_left_half_circle_thick,
			},
			color_overrides = {
				normal_mode = {
					a = { fg = colors.background, bg = colors.ansi[5] },
					b = { fg = colors.indexed[59], bg = colors.background },
					c = { fg = colors.indexed[59], bg = colors.background },
				},
				copy_mode = {
					a = { fg = colors.background, bg = colors.ansi[4] },
					b = { fg = colors.ansi[4], bg = colors.background },
					c = { fg = colors.foreground, bg = colors.background },
				},
				search_mode = {
					a = { fg = colors.background, bg = colors.ansi[3] },
					b = { fg = colors.ansi[3], bg = colors.background },
					c = { fg = colors.foreground, bg = colors.background },
				},
				-- Defining colors for a new key table
				window_mode = {
					a = { fg = colors.background, bg = colors.ansi[6] },
					b = { fg = colors.ansi[6], bg = colors.background },
					c = { fg = colors.foreground, bg = colors.background },
				},
				-- Default tab colors
				tab = {
					active = { fg = colors.ansi[6], bg = colors.background },
					inactive = { fg = colors.indexed[59], bg = colors.background },
					inactive_hover = { fg = colors.ansi[6], bg = colors.background },
				},
			},
		},
		sections = {
			tabline_a = {
				utils.leader_component,
				{ "mode", padding = { left = 1, right = 0 } },
			},
			tabline_b = { { "workspace", padding = { left = 1, right = 0 } } },
			tabline_c = { " " },
			tab_active = {
				-- { Background = { Color = tokyonight.brights[1] } },
				{
					"zoomed",
					icon = wezterm.nerdfonts.oct_zoom_in,
					padding = { left = 0, right = 0 },
				},
				{
					"index",
					padding = { left = 0, right = 1 },
				},
				{
					"tab",
					fmt = function(str)
						return utils.format_tab_title(str)
					end,
					padding = { left = 0, right = 0 },
					icons_enabled = false,
				},
				{ "parent", padding = { left = 0, right = 0 } },
				"/",
				{ "cwd", padding = { left = 0, right = 1 } },
				{ "process", padding = { left = 0, right = 0 } },
			},
			tab_inactive = {
				-- { Foreground = { Color = colors.brights[1] } },
				{
					"zoomed",
					icon = wezterm.nerdfonts.oct_zoom_in,
					padding = { left = 0, right = 0 },
				},
				{
					"index",
					padding = { left = 0, right = 1 },
				},
				{
					"tab",
					fmt = function(str)
						return utils.format_inactive_tab_title(str)
					end,
					padding = { left = 1, right = 0 },
					icons_enabled = false,
				},
				{ "cwd", padding = { left = 0, right = 1 } },
				{ "process", icons_only = true, padding = { left = 0, right = 0 } },
			},
			tabline_x = {},
			tabline_y = {
				{
					"datetime",
					icons_only = false,
					hour_to_icon = utils.hours_icons,
					padding = { left = 0, right = 1 },
					style = "%a %R",
				},
			},
			tabline_z = {
				-- { "hostname", padding = { left = 0, right = 1 } },
			},
		},
		extensions = { "resurrect" },
	})
end

return setup
