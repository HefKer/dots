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
config.bind(";r", "hint all right-click")
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
# Trigger file picker for drag-n-drop sites that hide their <input type=file>
config.bind(";u", "jseval -q document.querySelector('input[type=file]')?.click()")
# --- \testing ---
config.bind("<Ctrl-h>", "history")
config.bind("cs", "config-source")
config.bind("Q", "macro-record")
config.bind("q", "fake-key <Escape>")
config.bind("<Alt-Esc>", "fake-key <Escape>")
config.bind("gG", "tab-give")

config.bind("T", "cmd-set-text -s :tab-select")

config.bind(
    ",,",
    "config-cycle statusbar.show always in-mode ;; config-cycle tabs.show always switching",
)  # cycle showing statusbar and tabs
config.bind(
    ",tt",
    "config-cycle tabs.show always switching",
)  # cycle showing tabs only

# --- Darkmode ---
config.bind(
    ",td", "config-cycle colors.webpage.darkmode.enabled true false ;; reload"
)  # Toggle dark mode and reload the page automatically
config.unbind("tt")
config.unbind("tf")

# --- Spawn configs in nvim ---
config.bind("ce", "config-edit")


# Toggle dark mode for the current site (whole host, not just this page) and reload
config.bind(
    ",tw",
    "config-cycle -u *://{url:host}/* colors.webpage.darkmode.enabled true false ;; reload",
)


# --- Sessions ---
# Open cmd with quotes pre-filled, cursor moved inside via rl-backward-char
config.bind(
    ",sl", 'cmd-set-text :session-load -c "" ;; rl-backward-char'
)  # -c closes open windows on session load
config.bind(
    ",ss", 'cmd-set-text :session-save -o "" ;; rl-backward-char'
)  # -o saves only active window
config.bind(",sd", 'cmd-set-text :session-delete "" ;; rl-backward-char')

# --- User Scripts ---
config.unbind(",b")  # qute-rbw, replaced by qutewarden (,q*)

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
# [d]ownloads — act on the most recent download of this session
config.bind("edo", "download-open")
config.bind("edz", "download-open zathura {}")

config.bind("ewlc", "spawn --userscript wl-clean")
config.bind("ewlr", "spawn --userscript wl-hint-remove")

## qutewarden
config.bind(",qf", "spawn --userscript qutewarden fill")
config.bind(",qt", "spawn --userscript qutewarden totp")
config.bind(",qg", "spawn --userscript qutewarden generate")
config.bind(",qv", "spawn --userscript qutewarden vault --vault-allow-copy")
config.bind(",qu", "spawn --userscript qutewarden unlock")
config.bind(",ql", "spawn --userscript qutewarden lock")
config.bind(",qs", "spawn --userscript qutewarden sync")
config.bind(",qS", "spawn --userscript qutewarden status")

# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
