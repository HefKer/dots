# dots

My Linux desktop: [niri](https://github.com/YaLTeR/niri) +
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) on NixOS,
themed Everforest, and driven from the keyboard wherever possible:
[qutebrowser](qutebrowser/), [WezTerm](wezterm/), [Neovim](nvim/),
[herdr](herdr/) and [kanata](kanata/).

![qutebrowser with icon-only tabs on the left](qutebrowser/screenshots/overview.png)

Feel free to take whatever's useful. Most packages have a README with a
**Worth stealing** list: each entry is one feature, linked to the file it lives in
and the commit that added it. The commit message says why it's built that way.

## Highlights

- **qutebrowser:** [sessions you can park tabs in and pull them back out
  of](qutebrowser/README.md#session-append),
  [YouTube ad blocking that works](qutebrowser/README.md#youtube-adblock),
  [hint-driven focus for scrollable areas and hidden file
  inputs](qutebrowser/README.md#scrollable-hints), and
  [fixes for printing](qutebrowser/README.md#printing) and
  [dead hints after cross-site navigation](qutebrowser/README.md#injectfix)
- **WezTerm:** [quick select that copies URLs without the trailing
  punctuation](wezterm/README.md#quick-select-prose), and copies
  [inline code](wezterm/README.md#claude-inline-code) and
  [whole code blocks](wezterm/README.md#claude-code-blocks) out of Claude Code
- **Neovim + herdr:** [a prompt pane for writing to Claude Code in
  Neovim](nvim/README.md#prompt-pane), and
  [diff review with comments sent back to the agent](herdr/README.md#review)
- **kanata:** [home-row mods that don't misfire on fast
  rolls](kanata/README.md#home-row-mods), with
  [regression tests](kanata/README.md#tests)
- **fish:** [`nixup`](fish/README.md#nixup) and
  [`nixlog`](fish/README.md#nixlog) for checking nixpkgs updates before a
  rebuild, and [`cmv`](fish/README.md#cmv) for moving a project without losing
  its Claude Code sessions

## Packages

| Package | What it is | |
|---|---|---|
| [qutebrowser](qutebrowser/) | Keyboard-driven browser, with userscripts and greasemonkey scripts | [README](qutebrowser/README.md) |
| [wezterm](wezterm/) | Terminal, built around quick select | [README](wezterm/README.md) |
| [nvim](nvim/) | LazyVim, plus the Claude Code prompt pane | [README](nvim/README.md) |
| [herdr](herdr/) | Terminal multiplexer for coding agents | [README](herdr/README.md) |
| [fish](fish/) | Shell: vi keys, fzf, NixOS and Claude Code helpers | [README](fish/README.md) |
| [kanata](kanata/) | Keyboard remapper: home-row mods, layers, tests | [README](kanata/README.md) |
| [niri](niri/) | Scrolling Wayland compositor, split into one file per topic under `dms/` | |
| [DankMaterialShell](DankMaterialShell/) | Bar, launcher and theming for niri; generates the colour schemes the others read | |
| [starship](starship/) | Prompt, from the commented defaults | |
| [fastfetch](fastfetch/) | System info in Everforest, with icon keys in a frame | [screenshot](fastfetch/screenshots/fastfetch.png) |
| [btop](btop/) | Resource monitor, Everforest soft | |
| [atuin](atuin/) | Shell history search | |
| [fuzzel](fuzzel/) | App launcher and picker for the qutebrowser session scripts | |
| [hunk](hunk/) | Diff viewer used for reviewing agent changes | |
| [mpv](mpv/) | Video player | |
| [xdg-desktop-portal-termfilechooser](xdg-desktop-portal-termfilechooser/) | File picker portal: apps that use it get yazi in WezTerm | |
| [scripts](scripts/) | Helpers the configs call (prompt pane, qutebrowser sandbox) | |

Each package mirrors where its files go under `$HOME`, so
`qutebrowser/.config/qutebrowser/` is `~/.config/qutebrowser/`. To borrow a
config, copy that directory or just the file you want. Colours generally come
from DankMaterialShell, so swap in your own scheme where a README mentions
`dank-theme`.

## How this repo is wired

The rest is for me and for agents working in this repo: how these files reach
`$HOME` on my machines. This repo holds the files; it does not place them.
Home-manager, in the [NixOS config](https://github.com/HefKer/nixos-config), wires
them in. This directory is the **dotfiles root**.

### Layout

Each top-level dir is one application's package. Its tree mirrors where the
files appear under `$HOME`:

```
<pkg>/.config/<app>/...   →   ~/.config/<app>/...
```

Which paths are actually linked is the **link set**, declared in
[`homes/modules/dotfiles.nix`](https://github.com/HefKer/nixos-config/blob/main/homes/modules/dotfiles.nix): a shared layer every host gets, plus a
per-host layer on top. A file here that no entry names is not linked anywhere;
adding a package means adding an entry there and rebuilding once.

The links are **out-of-store symlinks**: `~/.config/<app>` resolves to this
directory, not to a copy in the Nix store. Editing a file here takes effect
immediately, with no rebuild, and applications that rewrite their own config
keep working. That is deliberate — store copies were considered and rejected
for machines I sit at, so don't "fix" it. See the NixOS config's
[ADR-0001](https://github.com/HefKer/nixos-config/blob/main/docs/adr/0001-dotfiles-wired-by-home-manager-as-out-of-store-symlinks.md) for the reasoning and the
[glossary](https://github.com/HefKer/nixos-config/blob/main/GLOSSARY.md) for the terms.

#### Bootstrapping a new machine

This directory must exist at `~/dots` **before the first rebuild**. Syncthing
is what puts it there. Nix cannot verify it: if it is missing, the rebuild
succeeds anyway, every link dangles silently, and the applications fail
obscurely (defaults, or errors reading their config) rather than loudly.

### What's linked where

| Pkg | App | Linked | Notes |
|-----|-----|--------|-------|
| [`fish`](fish/) | fish shell | `~/.config/fish/` | Vi keys, zoxide-shadowed `cd`, FZF widgets, custom `yt_chat` / `yt_summarize` functions wrapping the `claude` CLI. |
| [`niri`](niri/) | [niri](https://github.com/YaLTeR/niri) Wayland compositor | `~/.config/niri/`, plus `~/.config/niri-host.kdl` | `config.kdl` `include`s split files under `dms/` (binds, outputs, windowrules, …). Driven by DMS. Each host gets its own `host/<host>.kdl` (layout, touchpad) at the canonical name `niri-host.kdl`. |
| [`DankMaterialShell`](DankMaterialShell/) | [DMS](https://github.com/AvengeMedia/DankMaterialShell) niri shell | `~/.config/DankMaterialShell/` | Settings, themes, plugin metadata. |
| [`nvim`](nvim/) | Neovim | `~/.config/nvim/` | [LazyVim](https://www.lazyvim.org/) base. User plugins in `lua/plugins/`, config in `lua/config/`. |
| [`wezterm`](wezterm/) | [WezTerm](https://wezterm.org/) | `~/.config/wezterm/` | `wezterm.lua` loads `keys.lua` and sets `color_scheme = "dank-theme"` from `colors/dank-theme.toml`. |
| [`herdr`](herdr/) | [herdr](https://herdr.dev) agent multiplexer | `config.toml` only | See note below. |
| [`git`](git/) | git | `config` and `ignore` only | The directory takes git's runtime state (credential store, gitk), so the two files are linked alone. |
| [`qutebrowser`](qutebrowser/) | [qutebrowser](https://qutebrowser.org/) | `~/.config/qutebrowser/`, plus `userscripts/` | Multi-file config split across `appearance`, `privacy`, `filepicker`, `binds`, `search_engines`. Themes under `themes/`. Only `userscripts/` is linked under `~/.local/share/qutebrowser`, whose history and caches stay out of here. See deps below. |
| [`mpv`](mpv/) | [mpv](https://mpv.io/) | `~/.config/mpv/` | `mpv.conf` + `input.conf`. |

Directories are linked whole unless they hold runtime state, because an
application that saves by writing a temp file and renaming it over the target
destroys a file-level link.

> [!NOTE]
> `~/.config/herdr/` is also herdr's runtime state dir (`*.sock`, `session.json`, logs), so only `config.toml` is linked rather than the whole directory.

#### Unlinked dirs

- [`syncthing/`](syncthing/) — Shared `.stglobalignore` across all Syncthing folders/hosts. Not in the link set; placed by hand per Syncthing folder — see [`syncthing/README.md`](syncthing/README.md).
- [`kanata/`](kanata/) — The [kanata](https://github.com/jtroo/kanata) keymap shared by every keyboard. Not in the link set: the NixOS config's kanata services read `keymap.kbd` straight from here through a read-only bind, and each instance's `defcfg` (devices, TCP port) is generated there and `include`s this file. Edit it, then press Fn2+`\` (`lrld`) to live-reload. `keymap-drawer.yaml` gives the keymap viewer (Mod+/) legends for the aliases its parser can't read; the viewer redraws on every save.
- [`helium/`](helium/) — Browser extension settings (vimiumc), imported by hand in the browser rather than linked.
- [`wallpapers/`](wallpapers/) — Wallpapers, stored as lossless JPEG XL in Git LFS (needs `git-lfs`; `.githooks/pre-push` uploads them). DMS points at them directly via its saved `wallpaperPath`, so nothing links them.
- [`docs/`](docs/) — Written for agents working in this repo, not symlinked anywhere. [`agents/`](docs/agents/) says where issues live and how the triage labels and domain docs are read; [`adr/`](docs/adr/) records decisions that are hard to reverse.
- [`.claude/`](.claude/) — Repo-specific Claude Code skills, one per package. The global ignore drops `/.claude` wholesale, so `.gitignore` re-includes `skills/` on its own.
- [`.githooks/`](.githooks/) — Pre-commit syntax/format checks for staged configs (stylua, `fish -n`, `niri validate`, …). Enable once per clone with `git config core.hooksPath .githooks`.

### Application-written state

Config directories are linked whole, so anything an application writes at
runtime lands here too. That is contained with ignore rules rather than by
linking individual files:

- **git** — `.gitignore`, so `git status` reports only what is authored here.
- **Syncthing** — [`syncthing/.dotsignore`](syncthing/.dotsignore), so each host
  keeps its own copy instead of receiving the other's.

Both lists must stay in step. The load-bearing case is
`niri/.config/niri/dms/outputs.kdl`: DMS regenerates it from the compositor's
live outputs, so syncing it hands the laptop the desktop's monitor layout.

### Screenshots

A package's screenshots live in `<pkg>/screenshots/`, next to its README, named
for what they show (`hints.png`). Package roots are never linked, so the images
stay out of `$HOME`.

Every image is public for good, since LFS objects outlive a deleted file. So
each one comes from a **throwaway instance** that has the repo's config and none
of my data:

- **qutebrowser**: [`scripts/qute-sandbox`](scripts/qute-sandbox), or
  `--basedir` on a short path holding a copy of the config. The IPC socket lives
  under the basedir, and a long path overflows the socket path limit.
- **Terminal apps**: a new `wezterm start --always-new-process` window. Close it
  by killing its pid, since niri's close-window leaves wezterm's confirm prompt
  up.
- **Capture one window** with `niri msg action screenshot-window --id <id>
  --path <abs path>`, so nothing else on screen is in the image.

The DMS bar (notifications, media, window titles), atuin, btop and herdr's
sidebar show live personal data, so I take those myself. I look at every image
before it's committed.
