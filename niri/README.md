# niri

[niri](https://github.com/YaLTeR/niri) is a scrolling Wayland compositor.
`config.kdl` is niri's default config, with DankMaterialShell's binds and
look included from the files it generates under `dms/`. Each host's layout,
workspaces and touchpad live in `host/<host>.kdl`, which the nixos flake links
to `~/.config/niri-host.kdl`.

## Worth stealing

- <a id="dim-unfocused"></a>**Every window but the focused one fades.** One
  window rule sets unfocused windows to 80% opacity, on every screen, so focus
  shows at a glance while the focus ring stays slim.
  [`config.kdl`](.config/niri/config.kdl)
- <a id="fixed-workspaces-second-screen"></a>**Numbered workspaces that stay
  put on both screens.** Named workspaces persist when empty, so Mod+3 reaches
  workspace 3 without filling 1 and 2 first. Names are global, so the second
  screen's are prefixed, and Mod+N goes by position.
  [`desktop.kdl`](host/desktop.kdl)
- <a id="quick-run"></a>**Run the clipboard's command from anywhere.** Mod+;
  opens a small floating fish prompt with the copied command typed in, unrun
  until Enter, multi-line included. The output stays until a key, and a
  failure or a run over 10 s sends a notification. A second press focuses the
  open window. [`quick-run`](../scripts/quick-run)
