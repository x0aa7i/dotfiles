local wezterm = require("wezterm")
local act = wezterm.action

local FuzzyLaunch = "FUZZY|TABS|DOMAINS|WORKSPACES|COMMANDS|LAUNCH_MENU_ITEMS|KEY_ASSIGNMENTS"

local Alt = "ALT"
local LeaderShift = "LEADER|SHIFT"
local LeaderCtrl = "LEADER|CTRL"

local opts = {
	-- Leader key
	leader = { key = "`", mods = "", timeout_milliseconds = 1500 },

	-- Global keys
	keys = {
		{ key = "q", mods = "SUPER", action = act.QuitApplication },
		-- Reload Config
		{ key = "F5", mods = "LEADER", action = act.ReloadConfiguration },
		{ key = "F11", mods = "", action = wezterm.action.ToggleFullScreen },

		-- Clipboard
		{ key = "y", mods = "ALT", action = wezterm.action.ActivateCopyMode },
		{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action({ CopyTo = "Clipboard" }) },
		{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action({ PasteFrom = "Clipboard" }) },

		-- Close pane
		{ key = "q", mods = "ALT", action = act.CloseCurrentPane({ confirm = false }) },

		-- Split pane
		{ key = "\\", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- Activate pane directions
		-- { key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
		-- { key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
		-- { key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
		-- { key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },

		-- Resize pane mode
		{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
		{ key = "p", mods = "LEADER", action = act.ActivateKeyTable({ name = "window_mode", one_shot = false }) },

		-- Move pane to new window
		{
			key = "!",
			mods = LeaderShift,
			action = wezterm.action_callback(function(_, pane)
				pane:move_to_new_window()
			end),
		},

		-- Tabs
		-- { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		-- { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
		{ key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "SHIFT|ALT", action = act.MoveTabRelative(1) },
		{ key = "[", mods = "SHIFT|ALT", action = act.MoveTabRelative(-1) },

		{ -- Rename [T]ab
			key = "t",
			mods = LeaderCtrl,
			action = act.PromptInputLine({
				description = "Enter new name for the tab:",
				action = wezterm.action_callback(function(_, pane, line)
					if line then
						local tab = pane:tab()
						---@diagnostic disable-next-line: need-check-nil
						tab:set_title(line)
					end
				end),
			}),
		},

		-- { key = "t", mods = "CTRL|SHIFT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },

		-- Quick launch
		{
			key = "x",
			mods = LeaderCtrl,
			action = act.ShowLauncherArgs({
				title = "Quick Launch",
				flags = FuzzyLaunch,
			}),
		},

		-- Search
		{ key = "f", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "f", mods = Alt, action = act.Search("CurrentSelectionOrEmptyString") },

		{ -- btop
			key = "b",
			mods = "LEADER|CTRL",
			action = wezterm.action_callback(function(window, pane)
				window:perform_action(
					wezterm.action.SpawnCommandInNewTab({
						args = { "btop" },
					}),
					pane
				)
				-- window:active_tab():set_title("Resource Monitor")
			end),
		},

		{ key = "u", mods = LeaderCtrl, action = act.EmitEvent("toggle-tabbar") },
	},

	-- Conditional keybindings
	key_tables = {
		-- Resize Pane Mode
		resize_mode = {
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },

			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },

			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },

			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

			-- Cancel the mode by pressing escape
			{ key = "Escape", action = "PopKeyTable" },
		},

		-- Activate Pane Mode
		window_mode = {
			{ key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
			{ key = "h", action = act.ActivatePaneDirection("Left") },

			{ key = "RightArrow", action = act.ActivatePaneDirection("Right") },
			{ key = "l", action = act.ActivatePaneDirection("Right") },

			{ key = "UpArrow", action = act.ActivatePaneDirection("Up") },
			{ key = "k", action = act.ActivatePaneDirection("Up") },

			{ key = "DownArrow", action = act.ActivatePaneDirection("Down") },
			{ key = "j", action = act.ActivatePaneDirection("Down") },
		},

		-- Vim Copy Mode
		copy_mode = {
			{ key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },
			{ key = "Escape", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
			{ key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
			{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
			{ key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
			{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
			{ key = "c", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
			{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
			{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
			{ key = "f", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "g", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
			{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
			{ key = "q", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
			{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
			{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({
					{ CopyTo = "ClipboardAndPrimarySelection" },
					{ Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
				}),
			},
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
			{ key = "End", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "Home", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "LeftArrow", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "RightArrow", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
		},
	},

	mouse_bindings = {
		{ -- Left-Click: (Up) Select Text
			event = { Up = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = act.CompleteSelection("ClipboardAndPrimarySelection"),
		},
		{ -- Ctrl+Left-Click: (Up) Open Hyperlink
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.OpenLinkAtMouseCursor,
		},
		{ -- Ctrl+WheelUp: Go to previous tab
			event = { Down = { streak = 1, button = { WheelUp = 1 } } },
			mods = "CTRL",
			action = act.ActivateTabRelative(-1),
		},
		{ -- Ctrl+WheelDown: Go to next tab
			event = { Down = { streak = 1, button = { WheelDown = 1 } } },
			mods = "CTRL",
			action = act.ActivateTabRelative(1),
		},
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = act.PasteFrom("Clipboard"),
		},
	},
}

return opts
