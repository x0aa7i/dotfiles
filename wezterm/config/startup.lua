local wezterm = require("wezterm")

local M = {}

-- Maximize the window on startup
wezterm.on("gui-startup", function(cmd)
	-- allow `wezterm start -- something` to affect what we spawn
	-- in our initial window
	local args = {}
	if cmd then
		args = cmd.args
	end

	local workspace = "main"
	local project_dir = wezterm.home_dir .. "/dev"
	local tab, pane, window = wezterm.mux.spawn_window({
		workspace = workspace,
		cwd = project_dir,
		args = args,
	})

	-- pane:send_text("nvim\n")

	-- local _, dev_pane, _ = window:spawn_tab({ cwd = project_dir })
	-- dev_pane:send_text("dev\n")

	-- wezterm.mux.set_active_workspace(workspace)
	-- tab:activate()
	window:gui_window():maximize()
end)

return M
