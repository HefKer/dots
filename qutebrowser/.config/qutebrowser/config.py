"""
Reference:
[Bread config](https://github.com/BreadOnPenguins/dots/blob/master/.config/qutebrowser/config.py)
[config docs](qute://help/settings.html)
[translation service](https://github.com/AckslD/Qute-Translate)
[tab manager](https://codeberg.org/mister_monster/tab-manager)

userscript tutorial
http://www.ii.com/qutebrowser-userscripts-on-windows/
"""
# from qutebrowser.api import interceptor

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false

config.load_autoconfig()  # Load settings done via the GUI

# Colors
c.colors.completion.fg = "#899CA1"
c.colors.completion.category.fg = "#F2F2F2"
c.colors.completion.category.bg = "#555555"
c.colors.completion.item.selected.fg = "white"
c.colors.completion.item.selected.match.fg = "#0080FF"
c.colors.completion.item.selected.bg = "#333333"
c.colors.completion.item.selected.border.top = "#333333"
c.colors.completion.item.selected.border.bottom = "#333333"
c.colors.completion.match.fg = "#66FFFF"
c.colors.statusbar.normal.fg = "#899CA1"
c.colors.statusbar.normal.bg = "#222222"
c.colors.statusbar.insert.fg = "#899CA1"
c.colors.statusbar.insert.bg = "#222222"
c.colors.statusbar.command.bg = "#555555"
c.colors.statusbar.command.fg = "#F0F0F0"
c.colors.statusbar.caret.bg = "#5E468C"
c.colors.statusbar.caret.selection.fg = "white"
c.colors.statusbar.progress.bg = "#333333"
c.colors.statusbar.passthrough.bg = "#4779B3"
c.colors.statusbar.url.fg = c.colors.statusbar.normal.fg
c.colors.statusbar.url.success.http.fg = "#899CA1"
c.colors.statusbar.url.success.https.fg = "#53A6A6"
c.colors.statusbar.url.error.fg = "#8A2F58"
c.colors.statusbar.url.warn.fg = "#914E89"
c.colors.statusbar.url.hover.fg = "#2B7694"
c.colors.tabs.bar.bg = "#222222"
c.colors.tabs.even.fg = "#899CA1"
c.colors.tabs.even.bg = "#222222"
c.colors.tabs.odd.fg = "#899CA1"
c.colors.tabs.odd.bg = "#222222"
c.colors.tabs.selected.even.fg = "white"
c.colors.tabs.selected.even.bg = "#222222"
c.colors.tabs.selected.odd.fg = "white"
c.colors.tabs.selected.odd.bg = "#222222"
c.colors.tabs.indicator.start = "#222222"
c.colors.tabs.indicator.stop = "#222222"
c.colors.tabs.indicator.error = "#8A2F58"
c.colors.hints.bg = "#CCCCCC"
c.colors.hints.match.fg = "#000"
c.colors.downloads.start.fg = "black"
c.colors.downloads.start.bg = "#BFBFBF"
c.colors.downloads.stop.fg = "black"
c.colors.downloads.stop.bg = "#F0F0F0"
c.colors.keyhint.fg = "#FFFFFF"
c.colors.keyhint.suffix.fg = "#FFFF00"
c.colors.keyhint.bg = "rgba(0, 0, 0, 80%)"
c.colors.messages.error.bg = "#8A2F58"
c.colors.messages.error.border = "#8A2F58"
c.colors.messages.warning.bg = "#BF85CC"
c.colors.messages.warning.border = c.colors.messages.warning.bg
c.colors.messages.info.bg = "#333333"
c.colors.prompts.fg = "#333333"
c.colors.prompts.bg = "#DDDDDD"
c.colors.prompts.selected.bg = "#4779B3"

### Cosmetics

# Zen config
c.tabs.position = "left"

# c.tabs.show = "always"
config.set("tabs.show", "switching")
c.tabs.title.format = ""
c.tabs.title.format_pinned = ""
c.tabs.width = 36
c.tabs.padding = {"top": 4, "bottom": 4, "left": 4, "right": 4}
c.tabs.close_mouse_button = "none"
c.statusbar.show = "in-mode"  # Only shows statusbar when in insert/command modes
c.window.title_format = "{current_title}"
c.scrolling.bar = "never"
#
# Press 'tt' to toggle both the Tab bar and Status bar at once
config.bind(
    ",tt",
    "config-cycle tabs.show always switching",
)

config.bind(
    ",,",
    "config-cycle statusbar.show always in-mode ;; config-cycle tabs.show always switching",
)

# tabs
"""
c.tabs.position = "top"

if c.tabs.position == "top":
    pass
elif c.tabs.position == "left":
    c.tabs.width = "7%"  # default 15%

c.tabs.padding = {"top": 5, "bottom": 5, "left": 9, "right": 9}
"""
# c.tabs.indicator.width = 0  # no tab indicators
# c.window.transparent = True # apparently not needed

# dark mode setup
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
config.set("colors.webpage.darkmode.enabled", False, "file://*")

# Toggle dark mode and reload the page automatically
config.bind(",td", "config-cycle colors.webpage.darkmode.enabled true false ;; reload")

# Custom function to toggle darkmode for the current domain
for mode in ["true", "false"]:
    config.bind(f"t{mode[0]}", f"set -u {{url}} colors.webpage.darkmode.enabled {mode}")

# Toggle dark mode for ONLY the current website and reload
config.bind(
    ",tw", "config-cycle -u {url} colors.webpage.darkmode.enabled true false ;; reload"
)

# fonts
c.fonts.default_family = []
c.fonts.default_size = "13pt"
c.fonts.web.family.fixed = "monospace"
c.fonts.web.family.sans_serif = "monospace"
c.fonts.web.family.serif = "monospace"
c.fonts.web.family.standard = "monospace"

# others
c.scrolling.smooth = True

### keybinds

# General binds
if c.tabs.position == "top":
    config.bind("J", "tab-prev")
    config.bind("K", "tab-next")
else:
    config.bind("J", "tab-next")
    config.bind("K", "tab-prev")

config.bind("j", "scroll down")
config.bind("k", "scroll up")

config.bind("x", "tab-close -o")
config.bind("d", "scroll-page 0 0.5")
config.bind("u", "scroll-page 0 -0.5")
config.bind("U", "undo")

config.bind(";r", "hint all right-click")

config.bind("<Ctrl-h>", "history")

config.bind(",ym", "yank inline [{title}]({url:pretty})")  # Markdown yank

# Change start and default page
# Default: https://start.duckduckgo.com/
c.url.start_pages = ["https://github.com/hefker"]
c.url.default_page = "https://github.com/hefker"

"""
config.bind('=', 'cmd-set-text -s :open')
config.bind('cc', 'hint images spawn sh -c "cliphist link {hint-url}"')
config.bind('cs', 'cmd-set-text -s :config-source')
config.bind('tH', 'config-cycle tabs.show multiple never')
config.bind('sH', 'config-cycle statusbar.show always never')
config.bind('T', 'hint links tab')
config.bind('pP', 'open -- {primary}')
config.bind('pp', 'open -- {clipboard}')
config.bind('pt', 'open -t -- {clipboard}')
config.bind('qm', 'macro-record')
config.bind('<ctrl-y>', 'spawn --userscript ytdl.sh')
config.bind('tT', 'config-cycle tabs.position top left')
config.bind('gm', 'tab-move')
"""
# Focus binds
# config.bind("xb", "config-cycle statusbar.show always never")
# config.tind("xt", "config-cycle tabs.show always never")
# config.bind("xx", "config-cycle statusbar.show always never")

# Video binds
"""
check relevant sections:
https://gitlab.com/dwt1/dotfiles/-/blob/master/.config/qutebrowser/config.py

need to set up mpv for this to work:
config.bind('M', 'hint links spawn mpv {hint-url}')
# config.bind('Z', 'hint links spawn st -e youtube-dl {hint-url}')
config.bind('m', 'spawn mpv {url}')
config.bind('M', 'hint links spawn mpv {hint-url}')
"""
config.bind(",vv", "hint links spawn --detach mpv {hint-url}")
config.bind("<Alt-Esc>", "fake-key <Escape>")

### Other

# Search engines
c.url.open_base_url = True
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "!apkg": "https://archlinux.org/packages/?sort=&q={}&maintainer=&flagged=",
    "yt": "https://www.youtube.com/results?search_query={}",
    "y": "https://www.youtube.com/results?search_query={}",
    "gh": "https://github.com/search?o=desc&q={}&s=stars",
    "github": "https://github.com/search?o=desc&q={}&s=stars",
    # Google stuff
    "g": "https://www.google.com/search?q={}",
    "g.m": "https://www.google.com/maps?q={}",
    "g.s": "https://scholar.google.com/scholar?q={}",
    # Wikis
    "w": "https://www.wikipedia.org/w/index.php?search={}",
    "wiki": "https://www.wikipedia.org/w/index.php?search={}",
    "aw": "https://wiki.archlinux.org/?search={}",
    # Shopping
    "amazon": "https://www.amazon.com/s?k={}",
    "az": "https://www.amazon.com/s?k={}",
    "aliexpress": "https://www.aliexpress.com/wholesale?SearchText={}",
    "rb": "https://www.redbubble.com/shop/{}",
    "redbubble": "https://www.redbubble.com/shop/{}",
    # Socials
    "linkedin": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
    "li": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
}


# Privacy
# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True)
# config.set("content.webgl", False, "*")
# config.set("content.canvas_reading", False)
# config.set("content.geolocation", False)
# config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Adblocking
# You can also watch yt vids directly in mpv, see qutebrowser FAQ for how to do that.
# If you want additional blocklists, you can get the python-adblock package, or you can uncomment the ublock lists here.
c.content.blocking.enabled = True
# c.content.blocking.method = 'adblock' # uncomment this if you install python-adblock
# c.content.blocking.adblock.lists = [
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"]

# Sessions
c.auto_save.session = False

config.bind(",sl", "cmd-set-text -s :session-load ")
config.bind(",ss", "cmd-set-text -s :session-save ")
config.bind(",sd", "cmd-set-text -s :session-delete ")

### User Scripts

config.bind(",b", "spawn --userscript qute-bitwarden")
