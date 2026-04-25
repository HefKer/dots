# --- Privacy ---
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

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
