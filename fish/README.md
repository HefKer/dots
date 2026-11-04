# fish

My [fish](https://fishshell.com/) config: vi keys, fzf widgets, a
[starship](../starship/) prompt, and a set of functions for NixOS and Claude Code.

![fish with starship and fastfetch](../fastfetch/screenshots/fastfetch.png)

[`config.fish`](.config/fish/config.fish) is only an index. The config lives in
[`conf.d/`](.config/fish/conf.d/), one file per topic, loaded in filename order:

| File | What it holds |
|---|---|
| [`00-env.fish`](.config/fish/conf.d/00-env.fish) | Exported variables, `PATH`, vi key mode |
| [`10-tools.fish`](.config/fish/conf.d/10-tools.fish) | atuin |
| [`20-fzf.fish`](.config/fish/conf.d/20-fzf.fish) | fzf defaults and widgets (`Ctrl+F` files, `Ctrl+G` dirs) |
| [`30-alias.fish`](.config/fish/conf.d/30-alias.fish) | Aliases |
| [`40-abbr.fish`](.config/fish/conf.d/40-abbr.fish) | Abbreviations |
| [`50-hooks.fish`](.config/fish/conf.d/50-hooks.fish) | Event handlers |

Commands are autoloaded from [`functions/`](.config/fish/functions/), one per file.

## Worth stealing

### NixOS

- <a id="nixup"></a>**`nixup`: check for a newer version before rebuilding.**
  Compares an installed package, or all of them, against a nixpkgs channel, so
  you know what a rebuild would actually update.
  [`nixup.fish`](.config/fish/functions/nixup.fish) ·
  [5af88ff](https://github.com/HefKer/dots/commit/5af88ff),
  [05b00d2](https://github.com/HefKer/dots/commit/05b00d2)
- <a id="nixlog"></a>**`nixlog`: a package's upstream changelog.** Pulls the
  changelog or release notes for a nixpkgs package at a given version out of its
  source. [`nixlog.fish`](.config/fish/functions/nixlog.fish) ·
  [42088d8](https://github.com/HefKer/dots/commit/42088d8)
- <a id="hmopt"></a>**`hmopt`: search Home Manager options offline**, from the
  Nix store. [`hmopt.fish`](.config/fish/functions/hmopt.fish)

### Git

- <a id="hb"></a>**`hb`: review a branch in [hunk](https://github.com/modem-dev/hunk).**
  Pick a branch in fzf, most recently committed first, and review it against
  `main` from its merge-base, so only the branch's own commits show.
  [`hb.fish`](.config/fish/functions/hb.fish) ·
  [0ab1fe7](https://github.com/HefKer/dots/commit/0ab1fe7)
- <a id="wt-init"></a>**`wt-init`: bare repo + worktrees layout.** Clones a repo
  that way, or with `-m` migrates an existing clone in place.
  [`wt-init.fish`](.config/fish/functions/wt-init.fish)

### Claude Code

- <a id="cmv"></a>**`cmv`: move a project without losing its Claude sessions.**
  Claude Code files sessions by directory, so a plain `mv` strands them. `cmv`
  moves the sessions along, so `--resume` still finds them.
  [`cmv.fish`](.config/fish/functions/cmv.fish) ·
  [4b62e61](https://github.com/HefKer/dots/commit/4b62e61)
- <a id="yt"></a>**`yt_summarize` / `yt_chat`: talk about a YouTube video.**
  These fetch a video's transcript and hand it to Claude Code.
  [`yt_summarize.fish`](.config/fish/functions/yt_summarize.fish),
  [`yt_chat.fish`](.config/fish/functions/yt_chat.fish)

### Shell

- <a id="cd"></a>**`cd` through zoxide**, so plain `cd` also trains zoxide's
  database. [`cd.fish`](.config/fish/functions/cd.fish)
- <a id="rm"></a>**A safer `rm`** that asks once for 3+ files and reports what
  it removed. [`rm.fish`](.config/fish/functions/rm.fish)
- <a id="blank-line"></a>**A blank line between commands that the transient
  prompt doesn't draw over.** It's printed from a postexec hook instead of
  starship's `add_newline`.
  [`50-hooks.fish`](.config/fish/conf.d/50-hooks.fish) ·
  [e537aa1](https://github.com/HefKer/dots/commit/e537aa1)
