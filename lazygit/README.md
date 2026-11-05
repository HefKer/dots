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
- <a id="prune-merged"></a>**`X` deletes every branch merged into main, and
  its worktree.** It asks first, then reports each deletion in a popup. A
  worktree with changes or a branch with unmerged commits is kept, by git's own
  checks.
  [`git-prune-merged`](../scripts/git-prune-merged)
