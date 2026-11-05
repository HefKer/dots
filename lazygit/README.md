# lazygit

[lazygit](https://github.com/jesseduffield/lazygit) is a terminal UI for git.
`config.yml` is `lazygit --config`'s defaults with every option commented out,
and only the lines I changed uncommented. Colours are ANSI names, so they follow
the palette DMS generates for WezTerm: `cyan` is the DMS accent. herdr-lazygit's
sidebar pane loads this file first, then lays its own layout and keys over it.

## Worth stealing

- <a id="herdr-split-edit"></a>**`E` edits the selected file in a herdr split
  beside lazygit.** `e` still edits in lazygit's own pane. It calls the same
  script as yazi's herdr opener.
  [`config.yml`](.config/lazygit/config.yml)
