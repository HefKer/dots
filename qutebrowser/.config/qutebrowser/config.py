import shutil
from themes import everforest

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false

config.load_autoconfig()  # Load settings done via the GUI

# --- Cosmetics ---
everforest.set(c, "dark", "hard")  # options are dark/light and hard/medium/soft

# Zen config (tabs on left)
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

## dark mode setup
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
config.set("colors.webpage.darkmode.enabled", False, "file://*")

# Toggle dark mode and reload the page automatically
config.bind(",td", "config-cycle colors.webpage.darkmode.enabled true false")
# config.bind(",td", "config-cycle colors.webpage.darkmode.enabled true false ;; reload")

# Custom function to toggle darkmode for the current domain
for mode in ["true", "false"]:
    config.bind(f"t{mode[0]}", f"set -u {{url}} colors.webpage.darkmode.enabled {mode}")

# Toggle dark mode for ONLY the current website and reload
config.bind(
    ",tw",
    "config-cycle -u {url} colors.webpage.darkmode.enabled true false",
    # ",tw", "config-cycle -u {url} colors.webpage.darkmode.enabled true false ;; reload"
)

## fonts
c.fonts.default_family = []
c.fonts.default_size = "13pt"
c.fonts.web.family.fixed = "monospace"
c.fonts.web.family.sans_serif = "monospace"
c.fonts.web.family.serif = "monospace"
c.fonts.web.family.standard = "monospace"

## others
c.scrolling.smooth = True

# keybinds

## General binds
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
# c.editor.command = ["wezterm", "start", "--always-new-process", "--", "sh", "-c", "nvim {} && exit"]
c.editor.command = ["/home/hefker/.local/bin/qute-editor", "{}"]
# c.editor.command = ["wezterm", "start", "--always-new-process", "--", "nvim", "{}"]
# c.editor.command = ["wezterm", "start", "--", "nvim", "{}"]
# c.editor.command = ["wezterm", "start", "--always-new-process", "--", "sh", "-c", "nvim {} && exit"]
config.bind(",Sf", "spawn firefox {url}")
config.bind(",Sz", "spawn zen-browser {url}")
config.bind(",Sb", "spawn brave {url}")
config.bind("gD", "tab-clone")
config.bind("ce", "config-edit")

# Press 'tt' to toggle both the Tab bar and Status bar at once
config.bind(
    ",tt",
    "config-cycle tabs.show always switching",
)

config.bind(
    ",,",
    "config-cycle statusbar.show always in-mode ;; config-cycle tabs.show always switching",
)


# Sessions
c.auto_save.session = False

config.bind(",sl", "cmd-set-text -s :session-load ")
config.bind(",ss", "cmd-set-text -s :session-save ")
config.bind(",sd", "cmd-set-text -s :session-delete ")

### User Scripts

config.bind(",b", "spawn --userscript qute-bitwarden")

# Change start and default page
# Default: https://start.duckduckgo.com/
c.url.start_pages = ["https://github.com/hefker"]
c.url.default_page = "https://github.com/hefker"

"""
config.bind('=', 'cmd-set-text -s :open')
config.bind('cc', 'hint images spawn sh -c "cliphist link {hint-url}"')
config.bind('pP', 'open -- {primary}')
config.bind('pp', 'open -- {clipboard}')
config.bind('pt', 'open -t -- {clipboard}')
config.bind('<ctrl-y>', 'spawn --userscript ytdl.sh')
config.bind('tT', 'config-cycle tabs.position top left')
config.bind('gm', 'tab-move')
"""
config.bind("cs", "config-source")
config.bind("Q", "macro-record")
config.bind("q", "fake-key <Escape>")
config.bind("<Alt-Esc>", "fake-key <Escape>")

# Video binds
config.bind(",mf", "hint links spawn --detach mpv {hint-url}")
config.bind(",mm", "spawn --detach mpv {url}")
config.bind(",md", "hint links spawn st -e youtube-dl {hint-url}")

# --- Other ---

# Search engines
c.url.open_base_url = True
c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "!apkg": "https://archlinux.org/packages/?sort=&q={}&maintainer=&flagged=",
    "yt": "https://www.youtube.com/results?search_query={}",
    "y": "https://www.youtube.com/results?search_query={}",
    "gh": "https://github.com/search?o=desc&q={}&s=stars",
    "github": "https://github.com/search?o=desc&q={}&s=stars",
    "nix": "https://search.nixos.org/packages?channel=unstable&include_modular_service_options=1&include_nixos_options=1&query={}",
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
    "amz": "https://www.amazon.com/s?k={}",
    "az": "https://www.amazon.com/s?k={}",
    "aliexpress": "https://www.aliexpress.com/wholesale?SearchText={}",
    "rb": "https://www.redbubble.com/shop/{}",
    "redbubble": "https://www.redbubble.com/shop/{}",
    # Socials
    "linkedin": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
    "li": "https://www.linkedin.com/search/results/all/?keywords={}&origin=GLOBAL_SEARCH_HEADER",
}


# Use ranger as file picker
# Shout out: [Qutebrowser + Ranger = Pure Awesome - YouTube](https://www.youtube.com/watch?v=ce2NOmTBWfo)
def file_picker(manager="yazi"):
    wezterm = shutil.which("wezterm")
    shell = shutil.which("fish") or shutil.which("bash")

    if manager == "yazi":
        bin = shutil.which("yazi")
        if not all([wezterm, shell, bin]):
            return None, None
        cmd = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "yazi",
            "--",
            shell,
            "-c",
            f"{bin} --chooser-file={{}}",
        ]
        return cmd, cmd

    elif manager == "ranger":
        bin = shutil.which("ranger")
        if not all([wezterm, shell, bin]):
            return None, None
        single = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "ranger",
            "--",
            shell,
            "-c",
            f"{bin} --choosefile={{}}",
        ]
        multiple = [
            wezterm,
            "start",
            "--always-new-process",
            "--class",
            "ranger",
            "--",
            shell,
            "-c",
            f"{bin} --choosefiles={{}}",
        ]
        return single, multiple

    return None, None


single, multiple = file_picker("yazi")
if single and multiple:
    config.set("fileselect.handler", "external")
    config.set("fileselect.single_file.command", single)
    config.set("fileselect.multiple_files.command", multiple)

c.downloads.location.directory = "~/Downloads"

# Privacy
# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True) # Global incognito
# config.set("content.webgl", False, "*")
# config.set("content.canvas_reading", False)
# config.set("content.geolocation", False) # Block sites from asking for location
# config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Adblocking
c.content.blocking.enabled = True
c.content.blocking.method = "both"  # "adblock" / "both"
c.content.blocking.adblock.lists = [
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
]
