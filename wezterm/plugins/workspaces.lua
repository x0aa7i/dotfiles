local wezterm = require("wezterm")

-- Load Resurrect plugin
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local function setup(config)
	-- Set the periodic save interval
	resurrect.periodic_save({ interval_seconds = 60 * 10, save_workspaces = true, save_windows = true })
	resurrect.set_max_nlines(200)

	wezterm.on("augment-command-palette", function()
		local workspace_state = resurrect.workspace_state
		return {
			{
				brief = "Window | Workspace: Switch Workspace",
				icon = "md_briefcase_arrow_up_down",
				action = workspace_switcher.switch_workspace(),
			},
			{
				brief = "Window | Workspace: Rename Workspace",
				icon = "md_briefcase_edit",
				action = wezterm.action.PromptInputLine({
					description = "Enter new name for workspace",
					action = wezterm.action_callback(function(_, _, line)
						if line then
							wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
							resurrect.save_state(workspace_state.get_workspace_state())
						end
					end),
				}),
			},
		}
	end)

	workspace_switcher.workspace_formatter = function(label)
		return wezterm.format({
			{ Text = "󱂬 : " .. label },
		})
	end

	-- Load state whenever a workspace is created
	wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, _, label)
		local workspace_state = resurrect.workspace_state

		workspace_state.restore_workspace(resurrect.load_state(label, "workspace"), {
			-- window = window,
			relative = true,
			restore_text = true,
			on_pane_restore = resurrect.tab_state.default_on_pane_restore,
		})
	end)

	-- Save state whenever a workspace is selected
	wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(_, _, _)
		local workspace_state = resurrect.workspace_state
		resurrect.save_state(workspace_state.get_workspace_state())
	end)

	wezterm.on("resurrect.error", function(err)
		wezterm.log_error("ERROR!")
		wezterm.gui.gui_windows()[1]:toast_notification("resurrect", err, nil, 3000)
	end)

	wezterm.on("gui-startup", resurrect.resurrect_on_gui_startup)

	-- Key bindings
	table.insert(config.keys, { key = "o", mods = "ALT", action = workspace_switcher.switch_workspace() })
	table.insert(config.keys, { -- [S]ave workspace State
		key = "s",
		mods = "ALT",
		action = wezterm.action_callback(function()
			wezterm.log_info("Saved workspace")
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	})
	table.insert(config.keys, { -- [R]estore Session
		key = "r",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)") -- match before '/'
				id = string.match(id, "([^/]+)$") -- match after '/'
				id = string.match(id, "(.+)%..+$") -- remove file extention
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}
				if type == "workspace" then
					local state = resurrect.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					local state = resurrect.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
				end
			end)
		end),
	})
	table.insert(config.keys, {
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
	})
end

return setup
