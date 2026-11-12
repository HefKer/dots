# yazi

[yazi](https://yazi-rs.github.io) is a terminal file manager. The whole
`~/.config/yazi/` is linked, so `ya pkg`'s `package.toml` and the plugins it
installs live here too. The three TOML files are yazi's shipped defaults with
every option commented out, and only the lines I changed uncommented. The theme
uses ANSI colour names, so it follows the palette DMS generates for WezTerm.

## Worth stealing

- <a id="herdr-openers"></a>**Open files in a herdr split or tab beside yazi.**
  `e` opens the hovered or selected files in `$EDITOR` in a herdr split, `E` in
  a new herdr tab. Both are also in the `O` open-with menu, next to a WezTerm
  tab. yazi stays where it is.
  [`herdr-edit`](.config/yazi/scripts/herdr-edit)
- <a id="cd-on-quit"></a>**`y`: the shell follows yazi when it quits.** `Q`
  quits without moving.
  [`y.fish`](../fish/.config/fish/functions/y.fish)
- <a id="clipboard-and-drag"></a>**Hand files to GUI apps.** `c i` copies the
  hovered file's contents, so an image pastes into Discord or a browser as an
  image. `c r` opens the selection in a `ripdrag` window to drag it out with
  the mouse.
  [`keymap.toml`](.config/yazi/keymap.toml)
