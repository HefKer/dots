-- Pull in the wezterm API
local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.keys = require("keys")

-- config.color_scheme = 'AdventureTime'

config.default_prog = { "fish", "-l" }

--config.color_scheme = "Catppuccin Frappe"
config.color_scheme = "dank-theme"
config.window_background_opacity = 0.95
config.window_padding = { left = "2.0cell", right = "1.5cell", top = "0.7cell", bottom = "0.2cell" }

-- DMS regenerates dank-theme.toml and it has no tab bar section, so read the
-- tab colours from it here instead of hardcoding them
local scheme = wezterm.color.load_scheme(wezterm.config_dir .. "/colors/dank-theme.toml")
local bg, fg, accent = scheme.background, scheme.foreground, scheme.cursor_bg
config.colors = {
	tab_bar = {
		background = bg,
		active_tab = { bg_color = accent, fg_color = bg, intensity = "Bold" },
		inactive_tab = { bg_color = bg, fg_color = fg },
		inactive_tab_hover = { bg_color = scheme.ansi[1], fg_color = fg },
		new_tab = { bg_color = bg, fg_color = fg },
		new_tab_hover = { bg_color = scheme.ansi[1], fg_color = fg },
	},
}

config.font = wezterm.font("Victor Mono")
-- config.font = wezterm.font("JetBrains Mono")
config.font_size = 14

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 48
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true

-- The built-in url pattern is scheme + \S+, so a url in prose picks up the
-- punctuation around it. Stop at delimiters, keep balanced parens as in
-- Foo_(bar), and don't end on sentence punctuation. These patterns run before
-- the built-ins. No capture groups: quick select copies the last one that matched.
local url_char = [==[[^\s()\[\]{}<>"'`│]]==]
local url_end = [==[[^\s()\[\]{}<>"'`│,.;:!?*]]==]
local url_parens = [=[\([^\s()]*\)]=]
config.quick_select_patterns = {
	"(?:https?://|git@|git://|ssh://|ftp://|file://)(?:"
		.. url_char
		.. "|"
		.. url_parens
		.. ")*(?:"
		.. url_end
		.. "|"
		.. url_parens
		.. ")",
	-- The built-in path pattern allows dots anywhere, so a path ending a
	-- sentence keeps the period. Only a .. segment may end on a dot.
	[[(?:[.\w\-@~]+)?(?:/+[.\w\-@]+)*/+(?:[.\w\-@]*[\w\-@]|\.\.)]],
}

config.scrollback_lines = 20000
config.notification_handling = "SuppressFromFocusedWindow"
config.check_for_updates = false

return config
