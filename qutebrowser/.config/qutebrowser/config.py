config.load_autoconfig()  # Load settings done via the GUI

config.source("appearance.py")
config.source("privacy.py")
config.source("filepicker.py")
config.source("binds.py")
config.source("search_engines.py")

c.auto_save.session = False

c.completion.shrink = True
c.hints.auto_follow = "unique-match"
c.input.insert_mode.auto_enter = True
c.input.insert_mode.auto_leave = True
c.downloads.location.directory = "~/Downloads"

# Change start and default page
# Default: https://start.duckduckgo.com/
c.url.start_pages = ["https://github.com/hefker"]
c.url.default_page = "https://github.com/hefker"

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
