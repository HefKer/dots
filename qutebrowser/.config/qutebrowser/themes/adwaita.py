# Source: https://codeberg.org/tomenzgg/Adwaita-Theme-for-Qutebrowser/src/branch/master/draw.py#

"""
Setup:

from themes import adwaita
adwaita.set(c)

"""

def set(c, options={}):
    palette = {
        "background": "#F5F5F5",
        "background-alt": "#4A4F51",
        "background-statusbar": "#232729",  # 111111
        "border": "#929291",
        "current-line": "",
        "selection": "",
        "foreground": "#333333",
        "foreground-alt": "#B3B3B3",
        "foreground-bright": "#FFFFFF",
        "foreground-completion": "#D1D1D1",
        "foreground-dark": "#111111",
        "foreground-statusbar": "#EEEEEE",
        "insert": "#20561d",
        "passthrough": "#1d5656",
        "cyan": "#4A90D9",
        "green": "#52D94B",
        "orange": "#ff9257",  # d97e4a
        "pink": "#d94a9b",
        "purple": "#561d56",  # 8a2f8a  #d94ad7
        "red": "#ff4444",  # d94245
        "yellow": "#d9d94a",
    }

    ## Background color of the completion widget category headers.
    c.colors.completion.category.bg = palette["background"]

    ## Bottom border color of the completion widget category headers.
    c.colors.completion.category.border.bottom = palette["background-alt"]

    ## Top border color of the completion widget category headers.
    c.colors.completion.category.border.top = palette["background-alt"]

    ## Foreground color of completion widget category headers.
    c.colors.completion.category.fg = palette["background-statusbar"]

    ## Background color of the completion widget for even rows.
    c.colors.completion.even.bg = palette["background-statusbar"]

    ## Background color of the completion widget for odd rows.
    c.colors.completion.odd.bg = palette["background-statusbar"]

    ## Text color of the completion widget.
    c.colors.completion.fg = palette[
        "foreground-completion"
    ]  # palette['foreground-alt']
    # palette['foreground-statusbar']

    ## Background color of the selected completion item.
    c.colors.completion.item.selected.bg = palette["cyan"]

    ## Bottom border color of the selected completion item.
    c.colors.completion.item.selected.border.bottom = palette["cyan"]

    ## Top border color of the completion widget category headers.
    c.colors.completion.item.selected.border.top = palette["cyan"]

    ## Foreground color of the selected completion item.
    c.colors.completion.item.selected.fg = palette["foreground-bright"]

    ## Foreground color of the matched text in the completion.
    c.colors.completion.match.fg = palette["red"]

    ## Color of the scrollbar in completion view
    c.colors.completion.scrollbar.bg = palette["background-statusbar"]

    ## Color of the scrollbar handle in completion view.
    c.colors.completion.scrollbar.fg = palette["background"]

    ## Background color for the download bar.
    c.colors.downloads.bar.bg = palette[
        "foreground-dark"
    ]  # palette['background-statusbar']

    ## Background color for downloads with errors.
    c.colors.downloads.error.bg = palette["red"]

    ## Foreground color for downloads with errors.
    c.colors.downloads.error.fg = palette["background-statusbar"]

    ## Color gradient start for download backgrounds.
    c.colors.downloads.start.bg = palette["pink"]

    ## Color gradient start for download foregrounds.
    c.colors.downloads.start.fg = palette["background-statusbar"]

    ## Color gradient stop for download backgrounds.
    c.colors.downloads.stop.bg = palette["green"]

    ## Color gradient stop for download foregrounds.
    c.colors.downloads.stop.fg = palette["background-statusbar"]

    ## Color gradient interpolation system for download backgrounds.
    ## Type: ColorSystem
    ## Valid values:
    ##   - rgb: Interpolate in the RGB color system.
    ##   - hsv: Interpolate in the HSV color system.
    ##   - hsl: Interpolate in the HSL color system.
    ##   - none: Don't show a gradient.
    c.colors.downloads.system.bg = "hsv"

    ## Background color for hints. Note that you can use a `rgba(...)`
    ## value for transparency.
    c.colors.hints.bg = palette["background"]

    ## Font color for hints.
    c.colors.hints.fg = palette["foreground-dark"]

    ## Font color for the matched part of hints.
    c.colors.hints.match.fg = palette["background"]

    ## Background color of the keyhint widget.
    c.colors.keyhint.bg = palette["background-statusbar"]

    ## Text color for the keyhint widget.
    c.colors.keyhint.fg = palette["foreground-bright"]

    ## Highlight color for keys to complete the current keychain.
    c.colors.keyhint.suffix.fg = palette["cyan"]

    ## Background color of an error message.
    c.colors.messages.error.bg = palette["red"]

    ## Border color of an error message.
    c.colors.messages.error.border = palette["red"]

    ## Foreground color of an error message.
    c.colors.messages.error.fg = palette["foreground-bright"]

    ## Background color of an info message.
    c.colors.messages.info.bg = palette["background-statusbar"]

    ## Border color of an info message.
    c.colors.messages.info.border = palette["background-statusbar"]

    ## Foreground color an info message.
    c.colors.messages.info.fg = palette["foreground-statusbar"]

    ## Background color of a warning message.
    c.colors.messages.warning.bg = palette["yellow"]

    ## Border color of a warning message.
    c.colors.messages.warning.border = palette["yellow"]

    ## Foreground color a warning message.
    c.colors.messages.warning.fg = palette["background-statusbar"]

    ## Background color for prompts.
    c.colors.prompts.bg = palette["background-statusbar"]

    ## Foreground color for prompts.
    c.colors.prompts.fg = palette["foreground-statusbar"]

    ## Background color for the selected item in filename prompts.
    c.colors.prompts.selected.bg = palette["cyan"]

    ## Background color of the statusbar.
    c.colors.statusbar.normal.bg = palette["background-statusbar"]

    ## Foreground color of the statusbar.
    c.colors.statusbar.normal.fg = palette["foreground-alt"]

    ## Background color of the statusbar in command mode.
    c.colors.statusbar.command.bg = palette["background-statusbar"]

    ## Foreground color of the statusbar in command mode.
    c.colors.statusbar.command.fg = palette["foreground-statusbar"]

    ## Background color of the statusbar in private browsing mode.
    c.colors.statusbar.private.bg = palette["foreground-dark"]

    ## Foreground color of the statusbar in private browsing mode.
    c.colors.statusbar.private.fg = palette["foreground-statusbar"]

    ## Background color of the statusbar in private browsing + command mode.
    c.colors.statusbar.command.private.bg = palette["background"]

    ## Foreground color of the statusbar in private browsing + command mode.
    c.colors.statusbar.command.private.fg = palette["foreground-dark"]

    ## Background color of the progress bar.
    c.colors.statusbar.progress.bg = palette["foreground-alt"]

    ## Foreground color of the URL in the statusbar on error.
    c.colors.statusbar.url.error.fg = palette["red"]

    ## Default foreground color of the URL in the statusbar.
    c.colors.statusbar.url.fg = palette["foreground-alt"]

    ## Foreground color of the URL in the statusbar for hovered links.
    c.colors.statusbar.url.hover.fg = palette["cyan"]

    ## Foreground color of the URL in the statusbar on successful load
    c.colors.statusbar.url.success.http.fg = palette["green"]

    ## Foreground color of the URL in the statusbar on successful load
    c.colors.statusbar.url.success.https.fg = palette["green"]

    ## Foreground color of the URL in the statusbar when there's a warning.
    c.colors.statusbar.url.warn.fg = palette["yellow"]

    ## Background color of the statusbar in caret mode.
    c.colors.statusbar.caret.bg = palette["purple"]

    ## Foreground color of the statusbar in caret mode.
    c.colors.statusbar.caret.fg = palette["foreground-statusbar"]

    ## Background color of the statusbar in caret mode with a selection.
    c.colors.statusbar.caret.selection.bg = palette["purple"]

    ## Foreground color of the statusbar in caret mode with a selection.
    c.colors.statusbar.caret.selection.fg = palette["foreground-statusbar"]

    ## Background color of the statusbar in insert mode.
    c.colors.statusbar.insert.bg = palette["insert"]

    ## Foreground color of the statusbar in insert mode.
    c.colors.statusbar.insert.fg = palette["foreground-statusbar"]

    ## Background color of the statusbar in passthrough mode.
    c.colors.statusbar.passthrough.bg = palette["passthrough"]

    ## Foreground color of the statusbar in passthrough mode.
    c.colors.statusbar.passthrough.fg = palette["foreground-statusbar"]

    ## Background color of the tab bar.
    ## Type: QtColor
    c.colors.tabs.bar.bg = palette["border"]

    ## Background color of unselected even tabs.
    ## Type: QtColor
    c.colors.tabs.even.bg = palette["background-alt"]

    ## Foreground color of unselected even tabs.
    ## Type: QtColor
    c.colors.tabs.even.fg = palette["foreground-alt"]

    ## Background color of unselected odd tabs.
    ## Type: QtColor
    c.colors.tabs.odd.bg = palette["background-alt"]

    ## Foreground color of unselected odd tabs.
    ## Type: QtColor
    c.colors.tabs.odd.fg = palette["foreground-alt"]

    # ## Background color of selected even tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.even.bg = palette["background"]

    # ## Foreground color of selected even tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.even.fg = palette["foreground"]

    # ## Background color of selected odd tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.odd.bg = palette["background"]

    # ## Foreground color of selected odd tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.odd.fg = palette["foreground"]

    ## Color for the tab indicator on errors.
    ## Type: QtColor
    c.colors.tabs.indicator.error = palette["red"]

    ## Color gradient start for the tab indicator.
    ## Type: QtColor
    c.colors.tabs.indicator.start = palette["orange"]

    ## Color gradient end for the tab indicator.
    ## Type: QtColor
    c.colors.tabs.indicator.stop = palette["green"]

    ## Color gradient interpolation system for the tab indicator.
    ## Type: ColorSystem
    ## Valid values:
    ##   - rgb: Interpolate in the RGB color system.
    ##   - hsv: Interpolate in the HSV color system.
    ##   - hsl: Interpolate in the HSL color system.
    ##   - none: Don't show a gradient.
    c.colors.tabs.indicator.system = "none"
