# --- Privacy ---
# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True) # Global incognito
# config.set("content.webgl", False, "*")
# config.set("content.canvas_reading", False)
# config.set("content.geolocation", False) # Block sites from asking for location
# Browse through local Privoxy (privoxy.service), which routes out via Proton VPN;
# sites that break go in ~/dots/proxy/direct.txt to connect directly.
# TEMP off while fixing the router; re-enable after:
# c.content.proxy = "http://127.0.0.1:8118"
# WebRTC over TCP via the proxy only, so UDP can't leak the real IP around it.
config.set("content.webrtc_ip_handling_policy", "disable-non-proxied-udp")
config.set("content.cookies.accept", "all")  # Options: all, no-3rdparty
config.set("content.cookies.store", True)
# Bad certs on third-party resources are blocked silently; the page's own still asks.
config.set("content.tls.certificate_errors", "ask-block-thirdparty")
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

# Slack's desktop sign-in page (/ssb/signin_redirect) hands the token to the
# app by navigating to slack:// from JavaScript, which the default
# allow-from-user-interaction policy drops silently, leaving it on "Launching".
config.set("content.unknown_url_scheme_policy", "allow-all", "*://*.slack.com/*")

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

# Bypass Paywalls Clean's filters, whose network rules block paywall scripts. gitflic,
# its only host, answers qutebrowser's download with a 403, so `cu` mirrors the list to
# this path with curl (MIRRORS in the ubo-scriptlets userscript) before updating the
# adblock, and ports the element hiding and unlocking scriptlets the adblock skips.
# Appended rather than listed so ubo-scriptlets can still read the list above as a literal.
c.content.blocking.adblock.lists.append(
    (config.datadir / "adblock-lists" / "bpc-paywall-filter.txt").as_uri()
)

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
