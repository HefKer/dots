-- PROTOTYPE (hefker/dots-issues#54), throwaway: swayimg config for b-swayimg, one image per layer.
-- Loaded with -c instead of ~/.config/swayimg/init.lua. KEYMAP_DIR holds the layer SVGs, colors.lua and goto.

local dir = os.getenv("KEYMAP_DIR")
local viewer = swayimg.viewer

local function colors()
	local ok, c = pcall(dofile, dir .. "/colors.lua")
	return ok and c or { bg = 0xff1d1b20, fg = 0xffe6e0e9 }
end

local function apply_theme()
	local c = colors()
	viewer.set_window_background(c.bg)
	viewer.set_image_background(c.bg)
	swayimg.text.color = c.fg
end

swayimg.decoration = false
swayimg.imagelist.order = "alpha" -- 01-hrm.svg, 02-base.svg, ...
swayimg.imagelist.fsmon = false -- the watcher signals instead, after every layer is rewritten
-- No info overlay (empty scheme): only status messages, which name the layer on a jump.
swayimg.text.visible = true
viewer.text = { topleft = {}, topright = {}, bottomleft = {}, bottomright = {} }
viewer.default_scale = "fit"
viewer.default_position = "center"
viewer.loop = true
apply_theme()

local function layers()
	local out = {}
	for _, img in ipairs(swayimg.imagelist.get()) do
		table.insert(out, img.path)
	end
	table.sort(out)
	return out
end

local function show(path)
	viewer.open_path(path)
	swayimg.text.status = path:match("%d+%-(.-)%.svg$") or path
end

for i = 1, 9 do
	viewer.on_key(tostring(i), function()
		local l = layers()[i]
		if l then
			show(l)
		end
	end)
end
viewer.on_key({ "Next", "l", "Tab", "j" }, function()
	viewer.open("next")
end)
viewer.on_key({ "Prior", "h", "Shift+Tab", "k" }, function()
	viewer.open("prev")
end)
viewer.on_key("slash", function()
	-- fzf in a throwaway terminal; its pick comes back as USR2.
	os.execute("wezterm start --class kanata-keymap-search -- " .. os.getenv("KEYMAP_SEARCH") .. " --goto &")
end)
viewer.on_key({ "q", "Escape" }, function()
	swayimg.exit()
end)

-- USR1: the watcher redrew the layers (theme or keymap change).
viewer.on_signal("USR1", function()
	apply_theme()
	viewer.reload()
end)
-- USR2: b-search picked a layer.
viewer.on_signal("USR2", function()
	local f = io.open(dir .. "/goto")
	if not f then
		return
	end
	local name = f:read("l")
	f:close()
	for _, p in ipairs(layers()) do
		if p:match("%d+%-(.-)%.svg$") == name then
			show(p)
		end
	end
end)
