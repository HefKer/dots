from themes import everforest

# --- Looks ---
everforest.set(c, "dark", "hard")  # options are dark/light and hard/medium/soft

c.tabs.position = "left"
c.tabs.title.format = ""
c.tabs.title.format_pinned = ""
c.tabs.width = 36
c.tabs.padding = {"top": 4, "bottom": 4, "left": 4, "right": 4}
c.tabs.close_mouse_button = "none"
c.statusbar.show = "always"
c.window.title_format = "{current_title}"
c.scrolling.bar = "never"

## --- dark mode setup ---
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "smart"  # invert icons/logos, leave photos
# Leave already-dark backgrounds alone instead of flipping them light
c.colors.webpage.darkmode.threshold.background = 205
# Ask sites for their native dark theme; Chromium skips its filter on pages that declare one
c.colors.webpage.preferred_color_scheme = "dark"
config.set("colors.webpage.darkmode.enabled", False, "file://*")

## --- fonts ---
c.fonts.default_family = []
c.fonts.default_size = "13pt"
c.fonts.web.family.fixed = "monospace"
c.fonts.web.family.sans_serif = "monospace"
c.fonts.web.family.serif = "monospace"
c.fonts.web.family.standard = "monospace"

## --- Feel ---
c.scrolling.smooth = True
c.tabs.show = "always"  # opts: always, never, multiple, switching

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
