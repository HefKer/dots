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
config.bind("d", "scroll-page 0 0.5")
config.bind("u", "scroll-page 0 -0.5")
config.bind("U", "undo")
config.bind("gD", "tab-clone")
config.bind(";r", "hint all right-click")
config.bind("<Ctrl-h>", "history")
config.bind("cs", "config-source")
config.bind("Q", "macro-record")
config.bind("q", "fake-key <Escape>")
config.bind("<Alt-Esc>", "fake-key <Escape>")
config.bind("gG", "tab-give")

config.bind("T", "cmd-set-text -s :tab-select")
config.bind("gt", "tab-focus")  # buggy

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
for mode in ["true", "false"]:
    config.bind(
        f"t{mode[0]}", f"set -u {{url}} colors.webpage.darkmode.enabled {mode}"
    )  # Custom function to toggle darkmode for the current domain

# --- Spawn configs in nvim ---
c.editor.command = ["/home/hefker/.local/bin/qute-editor", "{}"]
c.editor.command = ["wezterm", "start", "--always-new-process", "--", "nvim", "{}"]
config.bind("ce", "config-edit")


# Toggle dark mode for ONLY the current website and reload
config.bind(
    ",tw",
    "config-cycle -u {url} colors.webpage.darkmode.enabled true false",
    # ",tw", "config-cycle -u {url} colors.webpage.darkmode.enabled true false ;; reload"
)


# --- Sessions ---
config.bind(",sl", "cmd-set-text -s :session-load ")
config.bind(",ss", "cmd-set-text -s :session-save ")
config.bind(",sd", "cmd-set-text -s :session-delete ")

# --- User Scripts ---
# config.bind(",b", "spawn --userscript qute-bitwarden")
config.bind(",b", "spawn --userscript qute-rbw")

# --- [E]xternal Spawn Commands ---
# [b]rowsers
config.bind("ebf", "spawn firefox {url}")
config.bind("ebz", "spawn zen-browser {url}")
config.bind("ebb", "spawn brave {url}")

# Video binds ([m]pv)
config.bind("emf", "hint links spawn --detach mpv {hint-url}")
config.bind("emm", "spawn --detach mpv {url}")
config.bind("emdf", "hint links spawn wezterm -e yt-dlp {hint-url}")
config.bind("emdd", "spawn wezterm -e yt-dlp {url}")


# Mute linter warnings
# ruff: noqa: F821
# pyright: reportUndefinedVariable=false
