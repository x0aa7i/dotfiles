local wezterm = require("wezterm")
-- local act = wezterm.action
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
-- local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local Keys = {}

local FuzzyLaunch = "FUZZY|TABS|DOMAINS|WORKSPACES|COMMANDS|LAUNCH_MENU_ITEMS|KEY_ASSIGNMENTS"

function Keys.setup(config)
	config.disable_default_key_bindings = true
	config.keys = {
		-- Delete word
		{ key = "Backspace", mods = "CTRL", action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }) },
		-- Activate pane directions
		{ key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "k", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "l", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "h", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "j", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "k", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "l", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
		-- Split panes
		{ key = [[|]], mods = "ALT|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = [[_]], mods = "ALT|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = [[-]], mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "v", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "s", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		-- Tabs
		{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
		{ key = "t", mods = "ALT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = false } }) },
		{ key = "Tab", mods = "CTRL", action = wezterm.action({ ActivateTabRelative = 1 }) },
		{ key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action({ ActivateTabRelative = -1 }) },
		{ key = "[", mods = "ALT", action = wezterm.action({ ActivateTabRelative = -1 }) },
		{ key = "]", mods = "ALT", action = wezterm.action({ ActivateTabRelative = 1 }) },
		{ key = "{", mods = "SHIFT|ALT", action = wezterm.action.MoveTabRelative(-1) },
		{ key = "}", mods = "SHIFT|ALT", action = wezterm.action.MoveTabRelative(1) },
		-- Close pane
		{ key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
		-- Zoom / Fullscreen
		{ key = "z", mods = "ALT", action = wezterm.action.TogglePaneZoomState },
		{ key = "F11", mods = "", action = wezterm.action.ToggleFullScreen },
		-- Clipboard
		{ key = "y", mods = "ALT", action = wezterm.action.ActivateCopyMode },
		{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action({ CopyTo = "Clipboard" }) },
		{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action({ PasteFrom = "Clipboard" }) },
		-- Activate tabs
		{ key = "1", mods = "ALT", action = wezterm.action({ ActivateTab = 0 }) },
		{ key = "2", mods = "ALT", action = wezterm.action({ ActivateTab = 1 }) },
		{ key = "3", mods = "ALT", action = wezterm.action({ ActivateTab = 2 }) },
		{ key = "4", mods = "ALT", action = wezterm.action({ ActivateTab = 3 }) },
		{ key = "5", mods = "ALT", action = wezterm.action({ ActivateTab = 4 }) },
		{ key = "6", mods = "ALT", action = wezterm.action({ ActivateTab = 5 }) },
		{ key = "7", mods = "ALT", action = wezterm.action({ ActivateTab = 6 }) },
		{ key = "8", mods = "ALT", action = wezterm.action({ ActivateTab = 7 }) },
		{ key = "9", mods = "ALT", action = wezterm.action({ ActivateTab = 8 }) },
		-- Key table for moving tabs around
		{
			key = "m",
			mods = "ALT",
			action = wezterm.action.ActivateKeyTable({ name = "move_tab", one_shot = false }),
		},
		{
			key = "r",
			mods = "ALT",
			action = wezterm.action.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
		},
		{
			key = "d",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_load(win, pane, function(id)
					resurrect.delete_state(id)
				end, {
					title = "Delete State",
					description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
					fuzzy_description = "Search State to Delete: ",
					is_fuzzy = true,
				})
			end),
		},
	}

	config.key_tables = {
		resize_pane = {
			{ key = "LeftArrow", action = wezterm.action.AdjustPaneSize({ "Left", 2 }) },
			{ key = "DownArrow", action = wezterm.action.AdjustPaneSize({ "Down", 2 }) },
			{ key = "UpArrow", action = wezterm.action.AdjustPaneSize({ "Up", 2 }) },
			{ key = "RightArrow", action = wezterm.action.AdjustPaneSize({ "Right", 2 }) },
			{ key = "h", action = wezterm.action.AdjustPaneSize({ "Left", 2 }) },
			{ key = "j", action = wezterm.action.AdjustPaneSize({ "Down", 2 }) },
			{ key = "k", action = wezterm.action.AdjustPaneSize({ "Up", 2 }) },
			{ key = "l", action = wezterm.action.AdjustPaneSize({ "Right", 2 }) },
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
		},
		move_tab = {
			{ key = "LeftArrow", action = wezterm.action.MoveTabRelative(-1) },
			{ key = "DownArrow", action = wezterm.action.MoveTabRelative(-1) },
			{ key = "UpArrow", action = wezterm.action.MoveTabRelative(1) },
			{ key = "RightArrow", action = wezterm.action.MoveTabRelative(1) },
			{ key = "h", action = wezterm.action.MoveTabRelative(-1) },
			{ key = "j", action = wezterm.action.MoveTabRelative(-1) },
			{ key = "k", action = wezterm.action.MoveTabRelative(1) },
			{ key = "l", action = wezterm.action.MoveTabRelative(1) },
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
		},
	}
end

return Keys
