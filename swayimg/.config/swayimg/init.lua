-- swayimg config, on top of the built-in defaults (share/swayimg/example.lua in the package).
-- Mainly drives the kanata keymap viewer (Mod+/), a tall SVG in a half-width window.

local viewer = swayimg.viewer
local step = 100

local function move(dx, dy)
	local pos = viewer.get_position()
	viewer.set_abs_position(pos.x + dx, pos.y + dy)
end

local function half_page()
	return math.floor(swayimg.get_window_size().height / 2)
end

-- The keymap fills the window's width and opens at its top; plain "optimal" fits the whole height, too small to read.
if swayimg.appid == "kanata-keymap" then
	viewer.default_scale = "width"
	viewer.default_position = "topcenter"
end

-- Vim motions move the view, so the image moves the other way.
viewer.on_key("h", function()
	move(step, 0)
end)
viewer.on_key("l", function()
	move(-step, 0)
end)
viewer.on_key("k", function()
	move(0, step)
end)
viewer.on_key("j", function()
	move(0, -step)
end)
viewer.on_key({ "u", "Ctrl+u" }, function()
	move(0, half_page())
end)
viewer.on_key({ "d", "Ctrl+d" }, function()
	move(0, -half_page())
end)
viewer.on_key("g", function()
	viewer.set_fix_position("topcenter")
end)
viewer.on_key("Shift+g", function()
	viewer.set_fix_position("bottomcenter")
end)
viewer.on_key("q", function()
	swayimg.exit()
end)

-- Scrolling moves the view like a page, the reverse of the default, which drags the image; ctrl+scroll still zooms.
viewer.on_scroll(function(kmods, horizontal, vertical)
	if kmods == "Ctrl" then
		if vertical then
			local mouse = swayimg.get_mouse_pos()
			local scale = viewer.scale
			viewer.set_abs_scale(scale - scale * vertical / 10.0, mouse.x, mouse.y)
		end
	else
		move(-math.floor(horizontal * 50), -math.floor(vertical * 50))
	end
end)
