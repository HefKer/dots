# herdr

[herdr](https://herdr.dev) is a terminal multiplexer built around coding agents.
It's where my Claude Code sessions, shells and editors live. Only
[`config.toml`](.config/herdr/config.toml) is linked, because
`~/.config/herdr/` also holds herdr's runtime state.

## Worth stealing

- <a id="prompt-pane"></a>**`prefix+a`: a Neovim prompt pane beside Claude.** It
  opens an nvim buffer next to the agent holding Claude's unsent prompt, and
  sends it back when you're done. See the
  [nvim README](../nvim/README.md#prompt-pane) for the editor side.
- <a id="review"></a>**`prefix+d`: review the agent's diff and comment back.**
  This opens [herdr-hunk-diff](https://github.com/jhochenbaum/herdr-hunk-diff)'s
  review pane, which refreshes as files change. `prefix+shift+s` sends the inline
  comments to the agent. Staged, branch and commit variants are on
  `prefix+shift+a/b/c`.
  [c230f5d](https://github.com/HefKer/dots/commit/c230f5d),
  [da30fe1](https://github.com/HefKer/dots/commit/da30fe1)
- <a id="smart-splits"></a>**`Ctrl+h/j/k/l` moves between herdr panes and nvim
  splits as one.** When nvim is the pane's foreground program, the keys go to
  nvim. At an edge with no neighbour, the pane gets the key, so `Ctrl+l` still
  clears a shell.
  [094dc2b](https://github.com/HefKer/dots/commit/094dc2b)
- <a id="tools"></a>**One-key tools.** `prefix+g` opens lazygit, `prefix+y`
  yazi, and `prefix+f` a floating shell, each through a herdr plugin.
- <a id="nav"></a>**Agent navigation.** `prefix+alt+j/k` cycles through agents,
  and `prefix+alt+1..9` jumps to the agent at that position in the sidebar.
  [4a2ee88](https://github.com/HefKer/dots/commit/4a2ee88),
  [e9f7f12](https://github.com/HefKer/dots/commit/e9f7f12)

The prefix is `Ctrl+Space`.
