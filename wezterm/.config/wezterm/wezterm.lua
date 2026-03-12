-- Pull in the wezterm API
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.keys = require("keys")
-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- config.color_scheme = 'AdventureTime'

config.default_prog = { "fish", "-l" }

config.color_scheme = "Catppuccin Frappe"
config.window_background_opacity = 0.95
local color_scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
local accent = "#babbf1" -- lavender

-- config.font = wezterm.font("Maple Mono")
config.font_size = 14

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 48

return config
