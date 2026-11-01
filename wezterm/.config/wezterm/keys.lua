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
		action = act.QuickSelect,
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
