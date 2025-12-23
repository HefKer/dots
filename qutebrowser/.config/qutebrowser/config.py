"""
Reference:
:config-source to reload config
[Bread config](https://github.com/BreadOnPenguins/dots/blob/master/.config/qutebrowser/config.py)
[config docs](qute://help/settings.html)
[translation service](https://github.com/AckslD/Qute-Translate)
[tab manager](https://codeberg.org/mister_monster/tab-manager)

bitwarden
https://github.com/qutebrowser/qutebrowser/blob/main/misc/userscripts/qute-bitwarden
https://github.com/haztecaso/bwmenu

Todo:
- Setup search engines: no arguments to open a certain default page
- adblocking
- smooth scroll
- Adblocking
- Logins (Bitwarden)
- Look into quickmarks/bookmarks
- Look into sessions
- Jumplist
"""

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false

config.load_autoconfig()  # Load settings done via the GUI

### Cosmetics

# Zen config
c.tabs.position = "left"

c.tabs.show = "always"
c.tabs.title.format = ""
c.tabs.title.format_pinned = ""
c.tabs.width = 36
c.tabs.padding = {"top": 4, "bottom": 4, "left": 4, "right": 4}
c.tabs.close_mouse_button = "none"
c.statusbar.show = "in-mode"  # Only shows statusbar when in insert/command modes
c.window.title_format = "{current_title}"
c.scrolling.bar = "never"

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

if c.tabs.position == "top":
    config.bind("J", "tab-prev")
    config.bind("K", "tab-next")
else:
    config.bind("J", "tab-next")
    config.bind("K", "tab-prev")

config.bind("j", "scroll down")
config.bind("k", "scroll up")

config.unbind("d")
config.unbind("u")
config.unbind("<Ctrl-U>")
config.unbind("<Ctrl-D>")

config.bind("x", "tab-close -o")
config.bind("d", "scroll-page 0 0.5")
config.bind("u", "scroll-page 0 -0.5")
config.bind("Ctrl-u", "undo")


"""
config.bind('=', 'cmd-set-text -s :open')
config.bind('h', 'history')
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
config.bind('gJ', 'tab-move +')
config.bind('gK', 'tab-move -')
config.bind('gm', 'tab-move')
"""

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
c.auto_save.session = True

config.bind(",sl", "cmd-set-text -s :session-load ")
config.bind(",ss", "cmd-set-text -s :session-save ")
config.bind(",sd", "cmd-set-text -s :session-delete ")
