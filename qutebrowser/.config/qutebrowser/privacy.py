# --- Privacy ---
# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True) # Global incognito
# config.set("content.webgl", False, "*")
# config.set("content.canvas_reading", False)
# config.set("content.geolocation", False) # Block sites from asking for location
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")  # Options: all, no-3rdparty
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Brave Search's bot check keeps re-flagging the stock QtWebEngine UA, which
# reports an old Chromium major; present as current desktop Chrome instead.
chrome_ua = "Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"
config.set("content.headers.user_agent", chrome_ua, "https://search.brave.com/*")

# ntv's stream player embeds a data: PDF to detect sandboxed iframes, and with
# plugins off the PDF fails, so it refuses to play: "Remove sandbox attributes
# on the iframe tag". The pattern matches the tab's page, not the player's
# rotating embed host.
for ntv in ("ntv.st", "ntv.cx"):
    config.set("content.plugins", True, f"*://*.{ntv}/*")

# Its stream host answers the stock UA with a 403, which the player reports as
# hls:networkError_manifestLoadError. Unlike content.plugins, the UA pattern is
# matched per request, so it has to name the stream host and not ntv.
config.set("content.headers.user_agent", chrome_ua, "*://*.indianservers.st/*")

# Adblocking
c.content.blocking.enabled = True
c.content.blocking.method = "both"  # "adblock" / "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    # filters.txt and privacy.txt pull these in with `!#include`, which qutebrowser's
    # adblock doesn't follow, so each is listed itself. A new year's list needs adding
    # here; `cu` (the ubo-scriptlets userscript) warns about any include missing.
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-general.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2025.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2026.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/ubo-link-shorteners.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    # "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
]

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
