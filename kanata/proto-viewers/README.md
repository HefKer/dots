# PROTOTYPE: keymap viewers (hefker/dots-issues#54)

Throwaway. Three ways to replace Mod+/'s swayimg viewer, to pick one from; none is wired to
Mod+/. Each runs from the repo root with one command, reads `kanata/keymap.kbd` through the
installed `kanata-keymap-render`'s keymap-drawer, and is colored from DMS's matugen palette
(`~/.cache/DankMaterialShell/dms-colors.json`), following theme changes and keymap edits live.

`keymapdata.py` is the shared data: keymap-drawer's parsed layers, joined with the raw kbd
action and alias behind each key, so a search for `esc` finds `Esc`, `@esc`, and `@cap`
(Caps taps Esc). Unmapped keys fall through to defsrc and are shown dimmed.

| | Launch | Layers | Search |
|---|---|---|---|
| (a) HTML | `kanata/proto-viewers/a-html` | `1`-`9`, `h`/`l`, Tab | `/`, live; every layer at once, hits highlighted, a hit list; Enter goes to the next layer with hits |
| (b) swayimg | `kanata/proto-viewers/b-swayimg` | `1`-`9`, PgUp/PgDn, `h`/`l`, Tab | `/` opens `b-search` (fzf); its pick jumps the viewer to that layer. `b-search` also runs alone |
| (c) TUI | `kanata/proto-viewers/c-tui` | `1`-`9`, `h`/`l`, Tab | `/`, live; hits highlighted on the grid, tab counts, a hit list; `n`/`N` cycle layers with hits |

`q` quits each. `APPID=…` overrides (a)'s and (b)'s app-id (default `kanata-keymap`, which
niri's floating rule matches).

## Gaps

- **All:** a layer held by an alias (Space → nav) isn't marked as held on its own layer;
  keymap-drawer only marks `layer-while-held` keys. Legends are kanata names (`lmet`,
  `C-rght`), not symbols.
- **(a):** qutebrowser, not chromium (chromium's `--app` ignores `--class` on Wayland, so niri
  can't match it); a throwaway `--temp-basedir` instance takes ~1-2 s to open. Mod+/ doesn't
  toggle it closed. No per-key detail on hover.
- **(b):** hits aren't highlighted in the images, only listed in fzf. fzf opens in a new
  WezTerm window (`kanata-keymap-search`) with no niri rule, so it tiles. Redrawing the layers
  takes ~3 s at start and after a theme change.
- **(c):** needs a terminal; no launcher with an app-id or niri rule yet (e.g.
  `wezterm start --class kanata-keymap -- kanata/proto-viewers/c-tui`). Needs ~107×30 cells;
  long legends are cut with `…`.
