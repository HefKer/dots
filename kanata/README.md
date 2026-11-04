# kanata

The [kanata](https://github.com/jtroo/kanata) keymap shared by every keyboard I
use. It isn't in the link set: the NixOS config's kanata services read
[`keymap.kbd`](keymap.kbd) straight from here, and each instance's `defcfg`
(devices, port) is generated there and `include`s this file. `Fn2+\` live-reloads
it.

## Worth stealing

- <a id="home-row-mods"></a>**Home-row mods that don't misfire while typing.**
  An opposite-hand key resolves on its release rather than its press, so a fast
  roll like `f`→`o` in "for" stays lowercase. A same-hand mod waits instead of
  forcing a tap, so `a`+`f` still chords. Tapping a key and then holding it within
  200 ms holds the letter itself, which keeps key repeat for `j`/`k` in vim. The
  whole block is marked so it can be deleted in one go.
  [`keymap.kbd`](keymap.kbd) ·
  [3bbffcf](https://github.com/HefKer/dots/commit/3bbffcf),
  [a216e73](https://github.com/HefKer/dots/commit/a216e73)
- <a id="tests"></a>**Regression tests for the keymap.** [`tests/`](tests/)
  holds the cases that `kanata-test` (in the NixOS config) runs, like typing a
  word at a given WPM and hold time and checking the output, so a timing change can't silently bring back
  an old misfire. [9335bd4](https://github.com/HefKer/dots/commit/9335bd4)
- <a id="caps"></a>**Caps Lock as Esc on tap and a function layer on hold.**
  [d608f70](https://github.com/HefKer/dots/commit/d608f70)
- <a id="passthrough"></a>**A passthrough layer for games.** It drops the
  tap-hold delays so key timing is exact. A watcher switches to it
  automatically, and both shifts + Esc toggle it by hand.
  [d608f70](https://github.com/HefKer/dots/commit/d608f70),
  [e3891cf](https://github.com/HefKer/dots/commit/e3891cf)
- <a id="viewer"></a>**An on-screen keymap viewer.** `Mod+/` in niri toggles a
  [keymap-drawer](https://github.com/caksoylar/keymap-drawer) render of the layers.
  [`keymap-drawer.yaml`](keymap-drawer.yaml) supplies legends for the aliases its
  parser can't read. [58ba1b1](https://github.com/HefKer/dots/commit/58ba1b1)
