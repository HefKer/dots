# herdr

[herdr](https://herdr.dev) is a terminal multiplexer built around coding agents.
It's where my Claude Code sessions, shells and editors live. Only
[`config.toml`](.config/herdr/config.toml) is linked, because
`~/.config/herdr/` also holds herdr's runtime state.

## Worth stealing

- <a id="prompt-pane"></a>**`prefix+a`: a full-screen Neovim prompt pane over Claude.**
  It opens a zoomed nvim buffer holding Claude's unsent prompt, and
  sends it back when you're done. See the
  [nvim README](../nvim/README.md#prompt-pane) for the editor side.
- <a id="account-switch"></a>**`prefix+u`: move the focused Claude session to
  your other account.** It exits an idle Claude and resumes the same session in
  the same pane under the other account, through the fish
  [`csend`](../fish/README.md#csend). For when one account's weekly limit runs out.
  An unsent prompt comes along, and a session with nothing sent yet starts afresh
  on the other account.
  It works from the [prompt pane](#prompt-pane) too, which keeps its draft, and
  shows a `hulio` badge in place of the statusline it covers.
  [`scripts/herdr-claude-account`](../scripts/herdr-claude-account)
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
- <a id="nav"></a>**Agent navigation.** `ctrl+alt+j/k` cycles through agents,
  `ctrl+alt+1..9` jumps to the agent at that position in the sidebar, and
  `ctrl+alt+a` walks the agents waiting on you: blocked on a question or
  approval, then finished unseen, then idle, each newest first, while its prompt
  cache is warm. Repeated presses skip agents already visited. Each lands on the tab's
  [prompt pane](#prompt-pane) instead of Claude when it has one (`prefix+alt+…`
  works too). Each agent's sidebar entry shows its context in tokens as `$ctx`,
  reported by the Claude statusline, and
  [`herdr-auto-title`](.config/herdr-auto-title/config.env) names tabs after their
  agent, not the prompt pane over it.
  [`scripts/herdr-agent-cycle`](../scripts/herdr-agent-cycle),
  [4a2ee88](https://github.com/HefKer/dots/commit/4a2ee88),
  [e9f7f12](https://github.com/HefKer/dots/commit/e9f7f12)
- <a id="agent-focus"></a>**`prefix+v`: keep agent navigation in this space.**
  The [agent-focus plugin](plugins/agent-focus/herdr-plugin.toml) narrows the
  agent sidebar, and with it `ctrl+alt+j/k` and `1..9`, to the current space's
  agents, plus any agent elsewhere that is blocked or finished unseen. The choice
  survives a server restart. The NixOS config registers it in place from this
  repo, so edits need no rebuild.
  [`agent-focus.py`](plugins/agent-focus/agent-focus.py)
- <a id="agent-notify"></a>**Clickable notifications for finished or blocked agents.**
  herdr's `system` toasts run a plain `notify-send` that ignores clicks. The
  [agent-notify plugin](plugins/agent-notify/herdr-plugin.toml) sends its own
  notification when an agent you aren't looking at finishes or blocks. Clicking it
  switches wezterm to the tab running herdr, raises that window in niri, and opens
  the agent: a finished Claude in its [prompt pane](#prompt-pane), reusing one
  already open, and a blocked one (a question or a permission prompt, which nvim
  doesn't answer) in its own pane. A newer status for the same pane replaces the old notification.
  [`agent-notify.py`](plugins/agent-notify/agent-notify.py)
- <a id="limits"></a>**Claude's usage limits in the tab bar.** The right of the
  tab row shows `5h 29% 3h17m · wk 52% 3d15h`: usage and time to reset of the
  account-wide limits, read from the newest render the Claude statusline shares.
  With a second account in use, its limits follow as `│ hulio 5h 3% · wk 1%`.
  [`scripts/claude-limits`](../scripts/claude-limits)

The prefix is `Ctrl+Space`.
