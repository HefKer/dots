# Source: "https://gitlab.com/lovetocode999/selenized-qutebrowser"

"""
Setup:

from themes import selenized
selenized.set(c)

"""

# Define the palette
selenized_palette = {
    "bg_0": "#103C48",
    "bg_1": "#184956",
    "bg_2": "#2D5B69",
    "dim_0": "#72898F",
    "fg_0": "#ADBCBC",
    "fg_1": "#CAD8D9",
    "red": "#fa5750",
    "green": "#75b938",
    "yellow": "#dbb32d",
    "blue": "#4695f7",
    "magenta": "#f275be",
    "cyan": "#41c7b9",
    "orange": "#ed8649",
    "violet": "#af88eb",
    "br_red": "#ff665c",
    "br_green": "#84c747",
    "br_yellow": "#ebc13d",
    "br_blue": "#58a3ff",
    "br_magenta": "#ff84cd",
    "br_cyan": "#53d6c7",
    "br_orange": "#fd9456",
    "br_violet": "#bd96fa",
}


def set(c):
    # Completion background
    c.colors.completion.category.bg = selenized_palette["bg_0"]
    c.colors.completion.category.border.bottom = selenized_palette["bg_0"]
    c.colors.completion.category.border.top = selenized_palette["bg_0"]
    c.colors.completion.even.bg = selenized_palette["bg_0"]
    c.colors.completion.odd.bg = selenized_palette["bg_0"]
    c.colors.completion.item.selected.bg = selenized_palette["bg_1"]
    c.colors.completion.item.selected.border.bottom = selenized_palette["bg_1"]
    c.colors.completion.item.selected.border.top = selenized_palette["bg_1"]
    c.colors.completion.scrollbar.bg = selenized_palette["bg_0"]

    # Completion foreground
    c.colors.completion.category.fg = selenized_palette["fg_1"]
    c.colors.completion.fg = selenized_palette["fg_0"]
    c.colors.completion.item.selected.fg = selenized_palette["fg_1"]
    c.colors.completion.item.selected.match.fg = selenized_palette["red"]
    c.colors.completion.match.fg = selenized_palette["orange"]
    c.colors.completion.scrollbar.fg = selenized_palette["dim_0"]

    # Download background
    c.colors.downloads.bar.bg = selenized_palette["bg_0"]
    c.colors.downloads.error.bg = selenized_palette["bg_0"]
    c.colors.downloads.start.bg = selenized_palette["bg_0"]
    c.colors.downloads.stop.bg = selenized_palette["bg_0"]

    # Download foreground
    c.colors.downloads.error.fg = selenized_palette["red"]
    c.colors.downloads.start.fg = selenized_palette["fg_0"]
    c.colors.downloads.stop.fg = selenized_palette["fg_0"]

    # Hint colors
    c.colors.hints.bg = selenized_palette["bg_0"]
    c.hints.border = "1px solid" + selenized_palette["bg_1"]
    c.colors.hints.fg = selenized_palette["fg_0"]
    c.colors.hints.match.fg = selenized_palette["fg_1"]

    # Keyhint colors
    c.colors.keyhint.bg = selenized_palette["bg_0"]
    c.colors.keyhint.fg = selenized_palette["fg_0"]
    c.colors.keyhint.suffix.fg = selenized_palette["fg_1"]

    # Message background
    c.colors.messages.error.bg = selenized_palette["bg_0"]
    c.colors.messages.error.border = selenized_palette["bg_0"]
    c.colors.messages.info.bg = selenized_palette["bg_0"]
    c.colors.messages.info.border = selenized_palette["bg_0"]
    c.colors.messages.warning.bg = selenized_palette["bg_0"]
    c.colors.messages.warning.border = selenized_palette["bg_0"]

    # Message Foreground
    c.colors.messages.error.fg = selenized_palette["red"]
    c.colors.messages.info.fg = selenized_palette["fg_0"]
    c.colors.messages.warning.fg = selenized_palette["orange"]

    # Prompt colors
    c.colors.prompts.bg = selenized_palette["bg_0"]
    c.colors.prompts.border = "1px solid" + selenized_palette["bg_0"]
    c.colors.prompts.fg = selenized_palette["fg_0"]
    c.colors.prompts.selected.bg = selenized_palette["bg_1"]

    # Status bar background
    c.colors.statusbar.caret.bg = selenized_palette["bg_0"]
    c.colors.statusbar.caret.selection.bg = selenized_palette["bg_0"]
    c.colors.statusbar.command.bg = selenized_palette["bg_0"]
    c.colors.statusbar.command.private.bg = selenized_palette["bg_0"]
    c.colors.statusbar.insert.bg = selenized_palette["bg_0"]
    c.colors.statusbar.normal.bg = selenized_palette["bg_0"]
    c.colors.statusbar.passthrough.bg = selenized_palette["bg_0"]
    c.colors.statusbar.private.bg = selenized_palette["bg_0"]
    c.colors.statusbar.progress.bg = selenized_palette["fg_0"]

    # Status bar foreground
    c.colors.statusbar.caret.fg = selenized_palette["magenta"]
    c.colors.statusbar.caret.selection.fg = selenized_palette["magenta"]
    c.colors.statusbar.command.fg = selenized_palette["fg_0"]
    c.colors.statusbar.command.private.fg = selenized_palette["fg_0"]
    c.colors.statusbar.insert.fg = selenized_palette["orange"]
    c.colors.statusbar.normal.fg = selenized_palette["fg_0"]
    c.colors.statusbar.passthrough.fg = selenized_palette["br_orange"]
    c.colors.statusbar.private.fg = selenized_palette["fg_0"]
    c.colors.statusbar.url.error.fg = selenized_palette["red"]
    c.colors.statusbar.url.fg = selenized_palette["fg_0"]
    c.colors.statusbar.url.hover.fg = selenized_palette["blue"]
    c.colors.statusbar.url.success.http.fg = selenized_palette["green"]
    c.colors.statusbar.url.success.https.fg = selenized_palette["green"]
    c.colors.statusbar.url.warn.fg = selenized_palette["orange"]

    # Tab bar background
    c.colors.tabs.bar.bg = selenized_palette["bg_2"]
    c.colors.tabs.even.bg = selenized_palette["bg_2"]
    c.colors.tabs.odd.bg = selenized_palette["bg_2"]
    c.colors.tabs.pinned.even.bg = selenized_palette["blue"]
    c.colors.tabs.pinned.odd.bg = selenized_palette["blue"]
    c.colors.tabs.pinned.selected.even.bg = selenized_palette["bg_0"]
    c.colors.tabs.pinned.selected.odd.bg = selenized_palette["bg_0"]
    c.colors.tabs.selected.even.bg = selenized_palette["bg_0"]
    c.colors.tabs.selected.odd.bg = selenized_palette["bg_0"]

    # Tab bar foreground
    c.colors.tabs.even.fg = selenized_palette["fg_0"]
    c.colors.tabs.odd.fg = selenized_palette["fg_0"]
    c.colors.tabs.pinned.even.fg = selenized_palette["fg_0"]
    c.colors.tabs.pinned.odd.fg = selenized_palette["fg_0"]
    c.colors.tabs.pinned.selected.even.fg = selenized_palette["fg_1"]
    c.colors.tabs.pinned.selected.odd.fg = selenized_palette["fg_1"]
    c.colors.tabs.selected.even.fg = selenized_palette["fg_1"]
    c.colors.tabs.selected.odd.fg = selenized_palette["fg_1"]

    # Tab indicator
    c.colors.tabs.indicator.error = selenized_palette["red"]
    c.colors.tabs.indicator.start = selenized_palette["green"]
    c.colors.tabs.indicator.stop = selenized_palette["green"]

    # Loading background
    c.colors.webpage.bg = selenized_palette["fg_0"]
