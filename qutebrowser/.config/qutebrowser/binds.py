# --- General binds ---
if c.tabs.position == "top":
    config.bind("J", "tab-prev")
    config.bind("K", "tab-next")
else:
    config.bind("J", "tab-next")
    config.bind("K", "tab-prev")

config.bind("j", "scroll down")
config.bind("k", "scroll up")

config.bind("x", "tab-close -o")
config.bind("<Ctrl-d>", "scroll-page 0 0.5")
config.bind("<Ctrl-u>", "scroll-page 0 -0.5")
# scroll-page doesn't work sometimes, fake-key is better
config.bind("d", "fake-key <PgDown>")
config.bind("u", "fake-key <PgUp>")
config.bind("U", "undo")
config.bind("gD", "tab-clone")
config.bind("gp", "open -p {url}")  # reopen the current page in a private window
config.bind("gP", "cmd-set-text -s :open -p")  # prompt, then open in a private window
config.bind(";r", "hint all right-click")
# Recover removed/dead content: [w]ayback's latest snapshot of this page or a hinted
# link; reverse-search a hinted image with Google [l]ens
config.bind("gw", "open -t https://web.archive.org/web/{url}")
config.bind(";w", "hint links run open -t https://web.archive.org/web/{hint-url}")
config.bind(";l", "hint images userscript reverse-img")
# --- testing ---
# Hint outermost/overlay elements to escape stubborn dialogs
c.hints.selectors["outer"] = [
    "body",
    "html",
    "div[class*=overlay]",
    "div[class*=modal]",
    "div[class*=backdrop]",
]
config.bind(";o", "hint outer")
# --- \testing ---
# Hint a paragraph and drop the caret at its start (Tridactyl-style caret placement)
# Source: https://github.com/vlify/qutebrowser-hint-caret
c.hints.selectors["para"] = [
    "p",
    "li",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "blockquote",
    "dd",
    "dt",
    "pre",
    "td",
    "th",
    "figcaption",
]
config.bind("v", "hint para userscript caret-anchor")
# caret.js's inline <style> is refused under a strict CSP (GitHub); caret-anchor adopts the
# same rules as a constructed stylesheet, so the refusal is noise.
c.content.javascript.log_message.excludes["userscript:_qute_js"] = [
    "*Refused to apply inline style because it violates the following Content Security Policy directive: *"
]
config.bind("<Ctrl-h>", "history")
config.bind("cs", "config-source")
config.bind("cc", "config-source --clear")  # --clear so deleted binds drop
config.bind("cb", "bookmarks-reload")
config.bind("cm", "quickmarks-reload")
# Replaces the default quickmark-save: the same name prompt, opened with the group
# Jev picks for the page already typed
config.bind("m", "spawn --userscript quickmark-file")
config.bind("cg", "greasemonkey-reload")
# refresh the adblock lists and regenerate the uBO scriptlets qutebrowser's adblock skips;
# the userscript runs :adblock-update itself, after mirroring the lists qutebrowser can't fetch
config.bind("cu", "spawn --userscript ubo-scriptlets")
config.bind("cn", "clear-messages")
config.bind("Q", "macro-record")
config.bind("q", "fake-key <Escape>")
config.bind("<Alt-Esc>", "fake-key <Escape>")

# --- Focus ---
JS = config.configdir / "js"
# Drop focus back to the page, e.g. off YouTube's volume slider
config.bind(";q", f"jseval -q -f {JS / 'blur.js'}")
# Hint a scrollable element or iframe to focus, so j/k etc. scroll it; with only
# two on screen, switch straight to the other one
config.bind(";s", "spawn --userscript js-hint --follow-lone scrollable")
c.hints.selectors["scrollable"] = ["[data-qb-hint=scrollable]"]
# Hint a file input, hidden ones too (drag-and-drop sites), to open the picker
config.bind(";u", "spawn --userscript js-hint upload normal")
c.hints.selectors["upload"] = ["[data-qb-hint=upload]"]

config.bind("gG", "tab-give")

config.bind("T", "cmd-set-text -s :tab-select")

config.bind(
    ",,",
    "config-cycle statusbar.show always in-mode ;; config-cycle tabs.show always switching",
)  # cycle showing statusbar and tabs
config.bind(
    ",ut",
    "config-cycle tabs.show always switching",
)  # cycle showing tabs only

# --- Darkmode ---
config.bind(
    ",ud", "config-cycle colors.webpage.darkmode.enabled true false ;; reload"
)  # Toggle dark mode and reload the page automatically

# --- Spawn configs in nvim ---
config.bind("ce", "config-edit")


# Toggle dark mode for the current site (whole host, not just this page) and reload.
# false comes first: a host with no override reads as unset, and config-cycle
# then picks the first value, so true-first made the first press a no-op.
config.bind(
    ",uw",
    "config-cycle -u *://{url:host}/* colors.webpage.darkmode.enabled false true ;; reload",
)


# --- Sessions ---
# Open cmd with quotes pre-filled, cursor moved inside via rl-backward-char
config.bind(",qL", 'cmd-set-text :session-load "" ;; rl-backward-char')
config.bind(
    ",ql", 'cmd-set-text :session-load --delete "" ;; rl-backward-char'
)  # --delete deletes saved session once loaded
config.bind(
    ",qs", 'cmd-set-text :session-save --only-active-window "" ;; rl-backward-char'
)
# Move a tab into a saved session without loading it (fuzzel picks the session):
# append it, then close it
config.bind(",qa", "spawn --userscript session-append --close")
config.bind(",qA", "hint links userscript session-append")  # a hinted link instead
# Open a tab from a saved session in a new tab (fuzzel picks session, then tab);
# like ,ql/,qL, lowercase removes it from the session and uppercase keeps it
config.bind(",qt", "spawn --userscript session-take")
config.bind(",qT", "spawn --userscript session-take --keep")

# --- [E]xternal Spawn Commands ---
# [b]rowsers
config.bind("ebz", "spawn zen-beta {url}")
config.bind("ebnz", "spawn zen-beta --blank-window {url}")
config.bind("ebh", "spawn helium {url}")
config.bind("ebnh", "spawn helium --new-window {url}")
# [f]ollow a hinted link into a new browser window
config.bind("ebfz", "hint links spawn zen-beta --blank-window {hint-url}")
config.bind("ebfh", "hint links spawn helium --new-window {hint-url}")
# [a]pp window (chromeless, no tabs/toolbar)
config.bind("ebah", "spawn helium --app={url}")
config.bind("ebfah", "hint links spawn helium --app={hint-url}")
# [p]hone (opened on mobile thru KDE Connect)
config.bind(
    "epp", "spawn kdeconnect-cli -d accffc5cb450442587102664350cbe3f --share {url}"
)
config.bind(
    "epf",
    "hint links spawn kdeconnect-cli -d accffc5cb450442587102664350cbe3f --share {hint-url}",
)

# Video binds ([m]pv)
config.bind(
    "emf",
    "hint links spawn --detach mpv --ytdl-raw-options=write-subs=,write-auto-subs= {hint-url}",
)
config.bind(
    "emm", "spawn --detach mpv --ytdl-raw-options=write-subs=,write-auto-subs= {url}"
)
config.bind(
    "emdf", "hint links spawn wezterm -e /home/hefker/.local/bin/ytdl {hint-url}"
)
config.bind("emdF", "hint --rapid links spawn /home/hefker/.local/bin/ytdl {hint-url}")
config.bind("emdd", "spawn wezterm -e /home/hefker/.local/bin/ytdl {url}")
# Save a hinted image as a [M]eme; the way in for Reddit, which refuses meme-add's logged-out download of a post page
config.bind("eM", "hint images spawn --detach meme-add {hint-url}")
# [d]ownloads — act on the most recent download of this session
config.bind("edo", "download-open")
config.bind("edz", "download-open zathura {}")
# [f]ile the newest download into the directory Jev picks for it, confirmed in a menu
config.bind("edf", "spawn --userscript download-file")

# [y]outube [w]atch later — [a]dd, hinted [f], [c]lean downloaded, [r]emove hinted
config.bind("eywc", "spawn --userscript wl-clean")
config.bind("eywr", "spawn --userscript wl-hint-remove")
c.hints.selectors["yt-video"] = ['a[href*="/watch?v="]', 'a[href*="/shorts/"]']
config.bind("eywa", "spawn --userscript wl-add")
config.bind("eywf", "hint yt-video userscript wl-add")

# [r]eddit — save a post (current page or hinted post link)
c.hints.selectors["reddit-post"] = ['a[href*="/comments/"]']
config.bind("ers", "spawn --userscript reddit-save")
config.bind("erf", "hint reddit-post userscript reddit-save")


# Speed and volume of the page's video; speed mirrors YouTube's own >/< keys
# Binds can't hold newlines, so the file goes in as one line, minus its comments
VIDEO_JS = " ".join(
    line.strip()
    for line in (JS / "video.js").read_text().splitlines()
    if not line.lstrip().startswith("//")
)


def video(action, step):
    return f"jseval -w main ({VIDEO_JS})('{action}', {step})"


config.bind("<Alt-.>", video("speed", 0.25))
config.bind("<Alt-,>", video("speed", -0.25))
config.bind("<Alt-/>", video("speed", 0))
config.bind("<Alt-k>", video("volume", 0.05))
config.bind("<Alt-j>", video("volume", -0.05))

## qutewarden ([p]asswords)
# Rare actions are aliases, so `:` completion finds them instead of a bind
c.aliases["vault-sync"] = "spawn --userscript qutewarden sync"
c.aliases["vault-status"] = "spawn --userscript qutewarden status"
config.bind(",pf", "spawn --userscript qutewarden fill")
config.bind(",pt", "spawn --userscript qutewarden totp")
config.bind(",pg", "spawn --userscript qutewarden generate")
config.bind(",pv", "spawn --userscript qutewarden vault --vault-allow-copy")
config.bind(",pc", "spawn --userscript qutewarden card")
config.bind(",pi", "spawn --userscript qutewarden identity")
config.bind(",pu", "spawn --userscript qutewarden unlock")
config.bind(",pl", "spawn --userscript qutewarden lock")

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
