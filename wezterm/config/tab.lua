local wezterm = require("wezterm")

local M = {}

-- Constants
M.arrow_solid = ""
M.arrow_thin = ""
M.icons = {
	["docker"] = "󰡨",
	["docker-compose"] = "󰡨",
	["nvim"] = "",
	["v"] = "",
	["bob"] = "",
	["vim"] = "",
	["node"] = "󰋘",
	["zsh"] = "",
	["bash"] = "",
	["htop"] = "",
	["btop"] = "",
	["go"] = "",
	["git"] = "󰊢",
	["lazygit"] = "󰊢",
	["lua"] = "",
	["wget"] = "󰄠",
	["curl"] = "",
	["gh"] = "",
	["flatpak"] = "󰏖",
	["dotnet"] = "󰪮",
	["paru"] = "󰣇",
	["yay"] = "󰣇",
	["fish"] = "",
	["Yazi"] = "",
}

-- Function to format the tab title
function M.format_tab_title(tab, max_width)
	local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or tab.active_pane.title
	local process, other = title:match("^(%S+)%s*%-?%s*%s*(.*)$")

	if M.icons[process] then
		title = M.icons[process] .. "  " .. (other or "")
	end

	local is_zoomed = false
	for _, pane in ipairs(tab.panes) do
		if pane.is_zoomed then
			is_zoomed = true
			break
		end
	end
	if is_zoomed then
		title = " " .. title
	end

	title = wezterm.truncate_right(title, max_width - 3)
	return " " .. title .. " "
end

-- Event handler for formatting tab titles
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = M.format_tab_title(tab, max_width)
	local colors = config.resolved_palette
	local active_bg = colors.tab_bar.active_tab.bg_color
	local inactive_bg = colors.tab_bar.inactive_tab.bg_color

	local tab_idx = 1
	for i, t in ipairs(tabs) do
		if t.tab_id == tab.tab_id then
			tab_idx = i
			break
		end
	end

	local is_last = tab_idx == #tabs
	local next_tab = tabs[tab_idx + 1]
	local next_is_active = next_tab and next_tab.is_active
	local arrow = (tab.is_active or is_last or next_is_active) and M.arrow_solid or M.arrow_thin
	local arrow_bg = inactive_bg
	local arrow_fg = colors.tab_bar.inactive_tab_edge

	if is_last then
		arrow_fg = tab.is_active and active_bg or inactive_bg
		arrow_bg = colors.tab_bar.background
	elseif tab.is_active then
		arrow_bg = inactive_bg
		arrow_fg = active_bg
	elseif next_is_active then
		arrow_bg = active_bg
		arrow_fg = inactive_bg
	end

	local ret = tab.is_active and {
		{ Attribute = { Intensity = "Bold" } },
	} or {}
	ret[#ret + 1] = { Text = title }
	ret[#ret + 1] = { Foreground = { Color = arrow_fg } }
	ret[#ret + 1] = { Background = { Color = arrow_bg } }
	ret[#ret + 1] = { Text = arrow }
	return ret
end)

-- Configuration options
local opts = {
	use_fancy_tab_bar = true,
	tab_bar_at_bottom = false,
	hide_tab_bar_if_only_one_tab = false,
	tab_max_width = 50,
	unzoom_on_switch_pane = true,
	show_new_tab_button_in_tab_bar = true,
}

return opts
