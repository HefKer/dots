# Neovim

A [LazyVim](https://www.lazyvim.org/) setup. LazyVim does most of the work. What's
here is the extras I enable, a few fixes, and a **prompt pane** for writing to
Claude Code from Neovim.

![Neovim with the DMS-generated Everforest colorscheme](screenshots/editing.png)

| Path | What it holds |
|---|---|
| [`lazyvim.json`](.config/nvim/lazyvim.json) | Enabled LazyVim extras (languages, Claude Code, smear-cursor, …) |
| [`lua/plugins/`](.config/nvim/lua/plugins/) | Plugin specs on top of LazyVim, one file per topic |
| [`lua/config/`](.config/nvim/lua/config/) | Options, keymaps, autocmds, and the prompt pane |

## Worth stealing

- <a id="outline"></a>**`gO` in a picker.** Neovim's `gO` outline opens a
  location-list split; here it opens a snacks picker instead: help, man,
  markdown and checkhealth buffers list their headings (even with an LSP
  attached, so markdown gets headings rather than marksman's symbols), and
  other buffers their LSP symbols. `<leader>o` opens it too. A pick jumps in
  the window it was opened from, not the one snacks would choose, so split
  layouts stay put.
  [`outline.lua`](.config/nvim/lua/config/outline.lua)
- <a id="prompt-pane"></a>**Prompt pane for Claude Code.** In
  [herdr](../herdr/), `prefix+a` opens an nvim scratch buffer zoomed over the
  Claude pane and moves Claude's unsent prompt into it. `<leader>as` sends the
  buffer to Claude. You get a full-screen editor for long prompts.
  - Claude's last reply sits rendered above the prompt, read from the session
    transcript and refreshed when a turn ends, so narration between tool calls
    never replaces it. `Alt+j/k/u/d` scroll it from the prompt, even in insert
    mode, and `[r`/`]r` step through earlier replies. Replies Claude ends
    several turns with, with no prompt of yours between (a background task
    finishing, say), join the one shown under a rule, keeping your place in it,
    so none is skipped behind the newest. So does the recap Claude writes when
    you come back after being away (`awaySummaryEnabled`).
  - The prompt is saved as you type, synced to disk, to
    `~/.local/state/nvim/claude-drafts/<session-id>.md`, and deleted once sent.
    A crash, reboot or power cut doesn't take it: the next `prefix+a` in the tab
    herdr resumes brings it back. `<leader>ad` picks from every other saved
    draft, for a pane that's gone, named by the project its session ran in.
  - Tables in the reply are redrawn as box grids whose cells wrap to fit the
    pane, so a wide table never breaks mid-row; quoting or yanking one takes its markdown.
  - `<CR>` in the reply quotes the list item, code block, table or paragraph
    under the cursor onto the end of the prompt, wherever its cursor was (a
    visual selection quotes just that), with an empty line under it to answer on. Quotes in the prompt are dimmed.
  - `<leader>aq` quotes the whole reply, and `<leader>aQ` strips the quoted
    lines again, leaving only what you wrote.
  - The reply's bar shows the model and effort level (`Opus 5.5 medium`), whether Claude is working, idle or blocked, with the
    tool call it's on while working (`working Edit prompt.lua`), its context in
    tokens, and 5-hour and weekly usage with the time to each reset,
    which the Claude statusline the pane covers shares in
    `$XDG_RUNTIME_DIR/claude-statusline/`.
  - <a id="permission-mode"></a>The reply's bar also shows Claude's permission
    mode (`plan`, `acceptEdits`, `auto`) when it isn't default, and
    `<leader>am` cycles it, as Shift+Tab in Claude's pane does. The transcript
    records the mode only as a turn starts, so the bar also reads the mode line
    under Claude's input box: a cycle shows within a second, made from here or
    in Claude's pane. [`config/prompt.lua`](.config/nvim/lua/config/prompt.lua)
  - The prompt's bar names Claude's directory and git branch
    (`~/nixos/main on main`), since the pane hides the statusline that shows
    them: writing to the agent in the wrong repo is easy with several tabs open.
  - `<leader>ak` swaps the reply for Claude's task list, rebuilt from its task
    tools in the transcript and updated as it works; the bar counts done tasks.
  - Each bar ends with its binds, most-used first, as many as fit on one line.
  - `<leader>ap` in any other nvim in the tab adds `@file`, or `@file#L10-20`
    for a selection, to the draft, relative to Claude's directory. It opens the
    prompt pane first if there isn't one, and focuses it to keep writing.
  - `/skill` and `@file` complete as they do in Claude's own input. Every line
    of the leading command block also completes the built-in, custom and plugin
    commands, with their descriptions. Both look up Claude's directory without
    waiting on herdr, so typing never stalls.
  - A draft starting with `!` runs in Claude's bash mode, as typing `!` in its
    input does: Claude reads the leading `!` of the send's paste the same way.
  - Slash commands leading the draft are a command queue: each is sent on its
    own, once the one before has finished (`/clear` once Claude is on the new
    session), and then the prose. `/clear`, `/model opus`, then a question, in
    one send. A command directly followed by text takes it as arguments. The
    queue runs in the background with its progress in the reply's bar, and
    pauses at a dialog or permission prompt (below), going on once it's
    answered. [`config/prompt_queue.lua`](.config/nvim/lua/config/prompt_queue.lua)
  - <a id="interrupt"></a>`<leader>ai`, or `Alt+c` even in insert mode,
    interrupts Claude's turn from the prompt pane, as Esc in its own pane does,
    and the reply's bar says so for a moment. A running command queue stops
    too, whatever it was waiting on, and what it hadn't sent yet goes back at
    the top of the draft. With Claude idle it only says so.
  - <a id="pending-call"></a>While Claude is blocked on a tool call, the reply
    gives way to the call: Bash's command, an edit's diff, the questions with
    their numbered options, or the plan to approve, then the dialog's own
    options. `<leader>ay` answers yes, `<leader>aY` yes and don't ask again,
    `<leader>an` no (Esc), `<leader>a1`..`<leader>a9` an option, each checked
    against the options on Claude's screen first, so a dialog laid out
    differently only notifies. Once answered, the reply is back. Claude can hold
    a call back from its transcript until it's answered; the dialog as its
    screen shows it stands in, diff and plan included. A send refused while
    blocked points at the binds; a queue reaching such a dialog waits for the
    answer. Free-text answers ("Type something", "Tell Claude what to change")
    are left to Claude's pane, through `<leader>ac`.
    [`config/prompt_pending.lua`](.config/nvim/lua/config/prompt_pending.lua)
  - <a id="hand-off"></a>When Claude opens a dialog the prompt pane can't answer
    (`/model`'s picker, or one whose options can't be read off the screen), the
    prompt pane hands off: Claude's pane comes up zoomed and focused, and once
    the dialog is answered the prompt pane is zoomed and focused again, the
    queue picking up where it paused. A send Claude refuses at such a dialog
    hands off too, and is sent once you're back. `<leader>ac` (or
    `:ClaudePane`) hands off on purpose, coming back once a dialog you open there closes. Only from a
    focused prompt pane; going elsewhere, or back by hand with the dialog still
    up, abandons the hand-off and puts the paused queue back in the draft.
    [`config/prompt_handoff.lua`](.config/nvim/lua/config/prompt_handoff.lua)
  - `<leader>ah` picks from every prompt sent before, newest first with its
    directory, and `<leader>at` from the templates in
    [`prompts/`](.config/nvim/prompts/), which put the cursor at their `$0`.
  - <a id="stash"></a>`<leader>al` stashes the pane's Claude session to come
    back to, with an optional note and the draft; `<leader>aL` stashes it and
    closes the agent, the prompt pane, and their tab if nothing else is in it.
    `<leader>aH` (or `:ClaudeSessions`) picks from every session on the machine,
    both accounts: stashed first, then this project's, then the rest, newest
    first, previewing the conversation. Enter resumes the pick in a new herdr
    tab, in its directory, under its own account, with the prompt pane over it
    and the stashed draft back in place; `Ctrl+X` unstashes without resuming.
    [`config/prompt_stash.lua`](.config/nvim/lua/config/prompt_stash.lua)
  - `Ctrl+V` with an image on the clipboard saves it to
    `$XDG_RUNTIME_DIR/claude-prompt-images/` and inserts its absolute path as an
    embed, previewed inline, for Claude to Read from any cwd.

  ![The prompt pane: Claude's reply above, two quoted list items answered in the prompt below](screenshots/prompt-pane.png)

  [`config/prompt.lua`](.config/nvim/lua/config/prompt.lua),
  [`config/prompt_source.lua`](.config/nvim/lua/config/prompt_source.lua),
  [`config/prompt_table.lua`](.config/nvim/lua/config/prompt_table.lua),
  [`config/prompt_stash.lua`](.config/nvim/lua/config/prompt_stash.lua),
  [`config/prompt_handoff.lua`](.config/nvim/lua/config/prompt_handoff.lua),
  [`config/prompt_pending.lua`](.config/nvim/lua/config/prompt_pending.lua),
  [`prompts/`](.config/nvim/prompts/),
  [`plugins/img-clip.lua`](.config/nvim/lua/plugins/img-clip.lua),
  [`scripts/claude-prompt`](../scripts/claude-prompt) ·
  [d3a5b24](https://github.com/HefKer/dots/commit/d3a5b24),
  [3a8052e](https://github.com/HefKer/dots/commit/3a8052e),
  [62b92e1](https://github.com/HefKer/dots/commit/62b92e1),
  [cb67a01](https://github.com/HefKer/dots/commit/cb67a01),
  [4eec5ac](https://github.com/HefKer/dots/commit/4eec5ac)
- <a id="habit-capture"></a>**Habit capture.** When you sense a better way
  existed, `<leader>hh` (or `:VimCapture`) asks what you were trying to do and
  appends an entry to a Vim inbox in the Obsidian vault: the last ~30 keys, the
  mode, file, and the text before and after them (the changed lines with context,
  or the cursor's surroundings when the keys only moved it). Buffers that may
  hold secrets (`*.age`, `*.gpg`, anything under `/tmp` or `/dev/shm`) give the
  note alone. `<leader>hi` opens the inbox; a Claude skill answers each entry
  with the idiomatic keys and files it as a drill.
  [`config/habit_capture.lua`](.config/nvim/lua/config/habit_capture.lua)
- <a id="markdown"></a>**Obsidian-style markdown.** On top of LazyVim's markdown
  extra, marksman resolves `[[wikilinks]]` by file name as Obsidian does and hides
  unresolved-link errors inside a vault, and markdownlint is cut down to rules
  that catch broken markdown rather than style.
  [`plugins/markdown.lua`](.config/nvim/lua/plugins/markdown.lua) ·
  [d3126c1](https://github.com/HefKer/dots/commit/d3126c1)
- <a id="paste-image"></a>**Paste images into an Obsidian vault.** In a markdown
  buffer, `Ctrl+V` saves a clipboard image the way the Obsidian app does: into the
  vault's attachment folder from `.obsidian/app.json`, named `Pasted image
  <timestamp>.png`, embedded as `![[name]]`. Any other clipboard content pastes as
  text. snacks.image also searches that folder, so name-only embeds render inline.
  `<leader>fn` likewise asks for a name and opens the note in the folder the app
  creates new notes in.
  [`config/obsidian.lua`](.config/nvim/lua/config/obsidian.lua),
  [`plugins/img-clip.lua`](.config/nvim/lua/plugins/img-clip.lua),
  [`config/keymaps.lua`](.config/nvim/lua/config/keymaps.lua) ·
  [e929a19](https://github.com/HefKer/dots/commit/e929a19)
- <a id="rename"></a>**Rename a file by its name alone.** `<leader>cR` and the
  explorer's rename prompt hold just the file name, without the directory or
  extension, and keep both. [`config/rename.lua`](.config/nvim/lua/config/rename.lua)
- <a id="smart-splits"></a>**`Ctrl+h/j/k/l` across nvim splits and herdr panes.**
  This uses [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
  v3 with a herdr backend. They work from insert mode too, leaving it first, and
  take `<C-k>` back from LSP and blink signature help.
  [`plugins/smart-splits.lua`](.config/nvim/lua/plugins/smart-splits.lua),
  [`config/keymaps.lua`](.config/nvim/lua/config/keymaps.lua) ·
  [46c0d28](https://github.com/HefKer/dots/commit/46c0d28)
- <a id="dms-colors"></a>**Fixing a generated colorscheme without editing it.**
  DankMaterialShell rewrites `colors/dms.lua` on every theme change, so the
  contrast fixes for `NonText` and `Visual` are reapplied after the colorscheme
  loads. [`plugins/colorscheme.lua`](.config/nvim/lua/plugins/colorscheme.lua) ·
  [1ead013](https://github.com/HefKer/dots/commit/1ead013)
- <a id="images"></a>**Full-size images on demand.** Markdown images show
  inline, which is small and soft, since WezTerm blurs a screenshot it shrinks
  that far. `<leader>ci` on an image link opens the image in a near-fullscreen
  float. `gf` opens it in a buffer, and `gx` opens it in your image viewer.
  [`plugins/snacks.lua`](.config/nvim/lua/plugins/snacks.lua)

## Using it yourself

- Mason is off for marksman, because Mason's build won't run on NixOS. The
  binary comes from Nix. On other distros you can let Mason install it.
- The prompt pane needs [herdr](https://herdr.dev) and Claude Code. The rest is
  plain LazyVim.
