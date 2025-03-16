--          ╭─────────────────────────────────────────────────────────╮
--          │                         COLORS                          │
--          ╰─────────────────────────────────────────────────────────╯
-- local tokyonight = require("themes.tokyonight")

local opts = {
	-- Color Scheme
	color_scheme_dirs = { "/home/abdo/.config/wezterm/colors" },
	color_scheme = "tokyonight_night",
	-- colors = tokyonight,
	-- Set colorscheme
	-- colors = colors,
	-- Tab Bar Colors
	-- colors = {
	-- 	compose_cursor = "#a5e3a0",
	-- 	visual_bell = "#E78284",
	-- },
	-- Command Palette Colors
	command_palette_bg_color = "#232634", -- Command Palette Background
	command_palette_fg_color = "#C6D0F5", -- Command Palette Foreground
	-- Titlebar and Frame Colors
	window_frame = {
		-- Titlebar Colors
		active_titlebar_bg = "#232634",
		inactive_titlebar_bg = "#303446",
		inactive_titlebar_fg = "#484D69",
		active_titlebar_fg = "#C6D0F5",
		inactive_titlebar_border_bottom = "#3b3052",
		active_titlebar_border_bottom = "#3b3052",

		-- Tab Bar Colors
		button_fg = "#C6D0F5",
		button_bg = "#3b3052",
		button_hover_fg = "#C6D0F5",
		button_hover_bg = "#2b2042",
		-- Tab Bar Font
		-- font = wezterm.font(types.win_font),
		-- Tab Font Size
		font_size = 10,
	},
	-- Inactive Pane Filter
	inactive_pane_hsb = {
		saturation = 1.0,
		brightness = 0.5,
	},
	-- Background translucency
	window_background_opacity = 1,
	-- Background gradient effect
	-- window_background_gradient = {
	-- 	orientation = {
	-- 		Linear = {
	-- 			angle = hour_angle,
	-- 		},
	-- 	},
	-- 	-- Gradient Colors
	-- 	colors = {
	-- 		"#24273a",
	-- 		"#1e1e2e",
	-- 	},
	-- 	-- Gradient Options
	-- 	interpolation = "CatmullRom",
	-- 	blend = "Oklab",
	-- 	noise = 128,
	-- 	segment_size = 7,
	-- 	segment_smoothness = 1.0,
	-- },
}

return opts
