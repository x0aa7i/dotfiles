--          ╭─────────────────────────────────────────────────────────╮
--          │                          TYPES                          │
--          ╰─────────────────────────────────────────────────────────╯

local M = {}

local wezterm = require("wezterm")

---@function Function to render the leader icon
---@return string leadericon The leader icon
function M.leader_component(window)
	if window:leader_is_active() then
		return " ! "
	end
	return ""
end

---@function Function to format the tab title
---@param title string The original tab title
---@return string new_string Formatted string
function M.format_tab_title(title)
	if title ~= "default" then
		return title .. wezterm.nerdfonts.ple_right_half_circle_thin
	else
		return ""
	end
end

---@function Function to format the tab title
---@param title string The original tab title
---@return string new_string Formatted string
function M.format_inactive_tab_title(title)
	if title ~= "default" then
		return title .. " "
	else
		return ""
	end
end

M.hours_icons = {
	["00"] = wezterm.nerdfonts.md_clock_time_twelve_outline,
	["01"] = wezterm.nerdfonts.md_clock_time_one_outline,
	["02"] = wezterm.nerdfonts.md_clock_time_two_outline,
	["03"] = wezterm.nerdfonts.md_clock_time_three_outline,
	["04"] = wezterm.nerdfonts.md_clock_time_four_outline,
	["05"] = wezterm.nerdfonts.md_clock_time_five_outline,
	["06"] = wezterm.nerdfonts.md_clock_time_six_outline,
	["07"] = wezterm.nerdfonts.md_clock_time_seven_outline,
	["08"] = wezterm.nerdfonts.md_clock_time_eight_outline,
	["09"] = wezterm.nerdfonts.md_clock_time_nine_outline,
	["10"] = wezterm.nerdfonts.md_clock_time_ten_outline,
	["11"] = wezterm.nerdfonts.md_clock_time_eleven_outline,
	["12"] = wezterm.nerdfonts.md_clock_time_twelve, -- 12:00 in solid icon
	["13"] = wezterm.nerdfonts.md_clock_time_one, -- 1:00 in solid icon
	["14"] = wezterm.nerdfonts.md_clock_time_two, -- 2:00 in solid icon
	["15"] = wezterm.nerdfonts.md_clock_time_three, -- 3:00 in solid icon
	["16"] = wezterm.nerdfonts.md_clock_time_four, -- 4:00 in solid icon
	["17"] = wezterm.nerdfonts.md_clock_time_five, -- 5:00 in solid icon
	["18"] = wezterm.nerdfonts.md_clock_time_six, -- 6:00 in solid icon
	["19"] = wezterm.nerdfonts.md_clock_time_seven, -- 7:00 in solid icon
	["20"] = wezterm.nerdfonts.md_clock_time_eight, -- 8:00 in solid icon
	["21"] = wezterm.nerdfonts.md_clock_time_nine, -- 9:00 in solid icon
	["22"] = wezterm.nerdfonts.md_clock_time_ten, -- 10:00 in solid icon
	["23"] = wezterm.nerdfonts.md_clock_time_eleven, -- 11:00 in solid icon
}

return M
