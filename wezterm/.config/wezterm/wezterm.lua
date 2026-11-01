-- Pull in the wezterm API
local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.keys = require("keys")

-- config.color_scheme = 'AdventureTime'

config.default_prog = { "fish", "-l" }

--config.color_scheme = "Catppuccin Frappe"
config.color_scheme = "dank-theme"
config.window_background_opacity = 0.95
config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0.25cell", bottom = "0.25cell" }

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

config.scrollback_lines = 20000
config.notification_handling = "SuppressFromFocusedWindow"
config.check_for_updates = false

return config
