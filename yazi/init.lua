require("git"):setup()

-- Responsive column ratios based on terminal width:
local last_layout = nil
local tab_layout = Tab.layout
Tab.layout = function(self, ...)
	local w = self._area and self._area.w or 0
	if w >= 4 then
		local p, c, v
		if w >= 90 then
			p, c, v = 2, 3, 4
		elseif w >= 50 then
			p, c, v = 0, 3, 4
		else
			p, c, v = 0, 1, 1
		end

		local key = p .. ":" .. c .. ":" .. v
		if last_layout ~= key then
			last_layout = key
			rt.mgr.ratio = { p, c, v }
		end
	end
	return tab_layout(self, ...)
end

require("relative-motions"):setup({
	-- show_motion = true,
	show_numbers = "relative_absolute",
	-- enter_mode = "first",
})

require("bookmarks"):setup({
	last_directory = { enable = false, persist = false, mode = "dir" },
	persist = "all",
	desc_format = "full",
	file_pick_mode = "hover",
	custom_desc_input = false,
	notify = {
		enable = false,
		timeout = 1,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})
