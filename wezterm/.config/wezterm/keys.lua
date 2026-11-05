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

-- The code blocks hinted by the last quick select, keyed by the text of the
-- screen row that holds each block's first line.
local block_by_row = {}

local copy_joined = wezterm.action_callback(function(win, pane)
	local text = win:get_selection_text_for_pane(pane)
	win:copy_to_clipboard(block_by_row[text] or join_hard_wrapped(pane, text))
end)

-- wezterm's built-in quick select patterns, which passing patterns replaces.
local builtin_patterns = {
	[==[\[[^]]*\]\(([^)]+)\)]==],
	[==[(?:https?://|git@|git://|ssh://|ftp://|file://)\S+]==],
	[==[--- a/(\S+)]==],
	[==[\+\+\+ b/(\S+)]==],
	[==[sha256:([0-9a-f]{64})]==],
	[==[(?:[.\w\-@~]+)?(?:/+[.\w\-@]+)+]==],
	[==[#[0-9a-fA-F]{6}]==],
	[==[[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}]==],
	[==[Qm[0-9a-zA-Z]{44}]==],
	[==[[0-9a-f]{7,40}]==],
	[==[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}]==],
	[==[[A-f0-9:]+:+[A-f0-9:]+[%\w\d]+]==],
	[==[0x[0-9a-fA-F]+]==],
	[==[[0-9]{4,}]==],
}

-- Claude Code drops the backticks around inline code and colours it bright blue
-- instead, and the Lua API can't read colours, so ask the cli for the escapes.
-- Short spans are skipped since they'd be hinted at every occurrence on screen.
local function inline_code(pane)
	local ok, text = wezterm.run_child_process({
		"env",
		"WEZTERM_UNIX_SOCKET=" .. os.getenv("XDG_RUNTIME_DIR") .. "/wezterm/gui-sock-" .. wezterm.procinfo.pid(),
		wezterm.executable_dir .. "/wezterm",
		"cli",
		"get-text",
		"--escapes",
		"--pane-id",
		tostring(pane:pane_id()),
	})
	local spans, seen = {}, {}
	if ok then
		for row in text:gmatch("[^\r\n]+") do
			for span in (row .. "\27["):gmatch("\27%[94m(.-)\27%[") do
				span = span:match("^%s*(.-)%s*$")
				if #span >= 3 and not seen[span] then
					seen[span] = true
					spans[#spans + 1] = span
				end
			end
		end
	end
	return spans
end

-- Claude Code drops a code block's fences and wraps its lines at the pane edge,
-- so the screen can't say where a block starts or ends. Inside herdr the
-- session transcript is reachable, and it has the block as written: hint the
-- row holding each block's first line, and copy the whole block when it's picked.
-- Short rows are skipped since text like `end` would be hinted everywhere.
local function code_block_rows(pane)
	block_by_row = {}
	local proc = pane:get_foreground_process_info()
	if not proc or not proc.executable:match("/herdr$") then
		return {}
	end
	local args = { "python3", "-I", wezterm.config_dir .. "/claude-code-blocks.py" }
	for _, arg in ipairs(proc.argv) do
		args[#args + 1] = arg
	end
	local ok, out = wezterm.run_child_process(args)
	local blocks = ok and wezterm.json_parse(out) or {}
	if #blocks == 0 then
		return {}
	end

	local rows = {}
	for row in (pane:get_lines_as_text() .. "\n"):gmatch("(.-)\n") do
		-- herdr draws its panes side by side, split by box-drawing borders.
		for segment in (row .. "│"):gmatch("(.-)│") do
			-- A block opening a message sits after Claude Code's bullet.
			segment = segment:match("^%s*(.-)%s*$")
			for _, bullet in ipairs({ "●", "⏺" }) do
				if segment:sub(1, #bullet) == bullet then
					segment = segment:sub(#bullet + 1):match("^%s*(.-)$")
				end
			end
			if #segment >= 6 then
				rows[#rows + 1] = segment
			end
		end
	end

	local found = {}
	-- Newest block first, so a row matching two blocks copies the latest.
	for _, block in ipairs(blocks) do
		local first = block:match("^%s*([^\n]-)%s*\n") or block:match("^%s*(.-)%s*$")
		for _, row in ipairs(rows) do
			-- The row is the line itself, or the part of it before a word wrap.
			local rest = first:sub(#row + 1, #row + 1)
			if not block_by_row[row] and first:sub(1, #row) == row and (rest == "" or rest == " ") then
				block_by_row[row] = block
				found[#found + 1] = row
			end
		end
	end
	return found
end

-- An empty list leaves quick select on its configured patterns. Otherwise the
-- spans come first, longest first, so one never loses to its own prefix.
local function hint_patterns(win, pane)
	local ok, rows = pcall(code_block_rows, pane)
	if not ok then
		wezterm.log_error("quick select code blocks: " .. tostring(rows))
		rows = {}
	end
	local spans = inline_code(pane)
	for _, row in ipairs(rows) do
		spans[#spans + 1] = row
	end
	if #spans == 0 then
		return {}
	end
	table.sort(spans, function(a, b)
		return #a > #b
	end)
	local patterns = {}
	for _, span in ipairs(spans) do
		patterns[#patterns + 1] = span:gsub("[%^%$%(%)%.%[%]%*%+%?{}|\\]", "\\%0")
	end
	for _, list in ipairs({ win:effective_config().quick_select_patterns, builtin_patterns }) do
		for _, pattern in ipairs(list) do
			patterns[#patterns + 1] = pattern
		end
	end
	return patterns
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
		action = wezterm.action_callback(function(win, pane)
			-- Never let a failed lookup cost us quick select itself
			local ok, patterns = pcall(hint_patterns, win, pane)
			if not ok then
				wezterm.log_error("quick select inline code: " .. tostring(patterns))
				patterns = {}
			end
			win:perform_action(act.QuickSelectArgs({ patterns = patterns, action = copy_joined }), pane)
		end),
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

-- herdr's switch_workspace takes ctrl+shift+1..9. WezTerm's ActivateTab
-- defaults also spell it as the shifted symbol, with and without SHIFT.
for i, shifted in ipairs({ "!", "@", "#", "$", "%", "^", "&", "*", "(" }) do
	for _, bind in ipairs({ { tostring(i), "CTRL|SHIFT" }, { shifted, "CTRL|SHIFT" }, { shifted, "CTRL" } }) do
		keys[#keys + 1] = { key = bind[1], mods = bind[2], action = act.DisableDefaultAssignment }
	end
end

return keys
