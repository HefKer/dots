local wezterm = require("wezterm")
local act = wezterm.action

-- Alt+j/k/u/d scrolling.
local function alt_scroll(key, scroll_action)
	return {
		key = key,
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			if pane:is_alt_screen_active() then
				win:perform_action(act.SendKey({ key = key, mods = "ALT" }), pane)
			else
				win:perform_action(scroll_action, pane)
			end
		end),
	}
end

-- Fullscreen TUIs such as Claude Code break long tokens into separate rows, so
-- quick select, which matches one logical line at a time, gets only the first
-- row. Text that ends a row at the right edge carries on at the start of the
-- next one, so add that.
local function join_hard_wrapped(pane, text)
	local cols = pane:get_dimensions().cols
	local rows = {}
	for row in (pane:get_lines_as_text() .. "\n"):gmatch("(.-)\n") do
		rows[#rows + 1] = row
	end

	for i, row in ipairs(rows) do
		if wezterm.column_width(row) == cols and row:sub(-#text) == text then
			local joined = text
			for j = i + 1, #rows do
				local next_row = rows[j]
				local piece = next_row:match("^%s*([^%s()%[%]{}<>\"'`]+)")
				if not piece then
					break
				end
				local reaches_edge = wezterm.column_width(next_row) == cols and next_row:sub(-#piece) == piece
				if not reaches_edge then
					return joined .. piece:gsub("[.,;:!?*]+$", "")
				end
				joined = joined .. piece
			end
			return joined
		end
	end
	return text
end

local keys = {
	{
		key = "t",
		mods = "ALT",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "q",
		mods = "ALT",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "Space",
		mods = "ALT",
		action = act.QuickSelectArgs({
			action = wezterm.action_callback(function(win, pane)
				win:copy_to_clipboard(join_hard_wrapped(pane, win:get_selection_text_for_pane(pane)))
			end),
		}),
	},
	{
		key = "c",
		mods = "ALT",
		action = act.ActivateCopyMode,
	},
	{
		key = "/",
		mods = "ALT",
		action = act.Search({ CaseInSensitiveString = "" }),
	},
	{
		key = "h",
		mods = "ALT",
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "l",
		mods = "ALT",
		action = act.ActivateTabRelative(1),
	},
	alt_scroll("k", act.ScrollByLine(-1)),
	alt_scroll("j", act.ScrollByLine(1)),
	alt_scroll("u", act.ScrollByPage(-0.5)),
	alt_scroll("d", act.ScrollByPage(0.5)),
	{
		key = "u",
		mods = "CTRL|ALT",
		action = act.ScrollByPage(-0.5),
	},
	{
		key = "d",
		mods = "CTRL|ALT",
		action = act.ScrollByPage(0.5),
	},
	{
		key = "b",
		mods = "CTRL|ALT",
		action = act.ScrollByPage(-1),
	},
	{
		key = "f",
		mods = "CTRL|ALT",
		action = act.ScrollByPage(1),
	},
	{
		key = "h",
		mods = "ALT|SHIFT",
		action = act.MoveTabRelative(-1),
	},
	{
		key = "l",
		mods = "ALT|SHIFT",
		action = act.MoveTabRelative(1),
	},
	-- leave these to the program in the pane
	{
		key = "Enter",
		mods = "ALT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
}

return keys
