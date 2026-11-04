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

- <a id="prompt-pane"></a>**Prompt pane for Claude Code.** In
  [herdr](../herdr/), `prefix+a` opens an nvim scratch buffer beside the Claude
  pane and moves Claude's unsent prompt into it. `<leader>as` sends the buffer to
  Claude. You get a real editor for long prompts while the agent stays visible
  and scrollable.
  - `<leader>aq` blockquotes Claude's last reply from the session transcript, so
    you can answer it inline.
  - `<leader>aQ` strips the quoted lines again, leaving only what you wrote.
  - `/skill` and `@file` complete as they do in Claude's own input.

  [`config/prompt.lua`](.config/nvim/lua/config/prompt.lua),
  [`config/prompt_source.lua`](.config/nvim/lua/config/prompt_source.lua),
  [`scripts/claude-prompt`](../scripts/claude-prompt) ·
  [d3a5b24](https://github.com/HefKer/dots/commit/d3a5b24),
  [3a8052e](https://github.com/HefKer/dots/commit/3a8052e),
  [62b92e1](https://github.com/HefKer/dots/commit/62b92e1),
  [cb67a01](https://github.com/HefKer/dots/commit/cb67a01)
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
  v3 with a herdr backend.
  [`plugins/smart-splits.lua`](.config/nvim/lua/plugins/smart-splits.lua) ·
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
