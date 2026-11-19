# DankMaterialShell

[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) is the bar,
launcher and theming for niri. The plugins under
[`plugins/`](.config/DankMaterialShell/plugins/) that git tracks are mine; the
rest are the plugin manager's clones.

## Worth stealing

- <a id="claude-limits"></a>**Claude's usage limits in the bar, for two
  accounts.** The bar shows `main 5h 29% · wk 52%` for the account of the
  Claude last used, read from the newest render the Claude statusline shares.
  A click switches to the other account until a Claude is next used; hover
  shows the reset times and the other account's figures.
  [`ClaudeLimitsWidget.qml`](.config/DankMaterialShell/plugins/claudeLimits/ClaudeLimitsWidget.qml)
