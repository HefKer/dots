# kanata

The [kanata](https://github.com/jtroo/kanata) keymap shared by every keyboard I
use. It isn't in the link set: the NixOS config's kanata services read
[`keymap.kbd`](keymap.kbd) straight from here, and each instance's `defcfg`
(devices, port) is generated there and `include`s this file. `Fn2+\` live-reloads
it.

## Wooting settings

The Wooting's analog settings stay in its firmware ([ADR-0005](https://github.com/HefKer/nixos-config/blob/main/docs/adr/0005-remapper-owns-digital-keyboard-features.md))
but decide when kanata sees a key go down and up, so misfire hunting starts here.

- **Actuation point:** 2.5 mm, so a key goes down later in its travel.
- **Rapid trigger:** sensitive (lifts register immediately) on every key. Target
  for the home-row mods `a s d f j k l ;`: 0.3–0.5 mm, so a slight lift mid-hold
  isn't a release and a new press. Update this line once it's set in Wootility.

Short windows make a key nested inside a mod's hold common, and a lift can
become a tap; [`tests/lift.sim`](tests/lift.sim) pins what kanata does then.
`kanata-test --fuzz` reports a `wooting` profile of 30–90 ms holds, a guess
until the real windows are measured.

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
- <a id="space-layer"></a>**Space as a vim-shaped navigation layer on hold,
  for apps without vim keys.** `hjkl` are arrows, `d`/`f` are plain Ctrl and Shift
  (word motions, selection), and the left hand has vim-lettered macros: `a`
  opens a line, `x` deletes it, `e` changes a word, `y` yanks the line, and with
  `f` held each gives its capital (`O`, `D`, `C`). Backspace, Delete and Enter
  sit under the right hand. Space pressed mid-word stays Space, and tapping it
  then holding it repeats Space. [`keymap.kbd`](keymap.kbd)
- <a id="passthrough"></a>**A passthrough layer for games.** It drops the
  tap-hold delays so key timing is exact. A watcher switches to it
  automatically, and both shifts + Esc toggle it by hand.
  [d608f70](https://github.com/HefKer/dots/commit/d608f70),
  [e3891cf](https://github.com/HefKer/dots/commit/e3891cf)
- <a id="game-layer"></a>**A game layer with arrows on the right modifiers.**
  Stock keys with no tap-hold, plus arrows on `/`, right Alt, Super, Menu and
  Ctrl, for games that want both WASD and arrows. The same watcher switches to
  it while a Steam game has focus, and passthrough stays for osu.
  [`keymap.kbd`](keymap.kbd)
- <a id="stardew-layer"></a>**A per-game layer: Stardew Valley's animation
  cancel on Space.** The game layer, with Space pressing Right Shift, Delete
  and R together, so one tool does all remapping instead of xremap beside
  kanata. The watcher picks it by the game's app id. [`keymap.kbd`](keymap.kbd)
- <a id="viewer"></a>**An on-screen keymap viewer.** `Mod+/` in niri toggles a
  [keymap-drawer](https://github.com/caksoylar/keymap-drawer) render of the layers.
  [`keymap-drawer.yaml`](keymap-drawer.yaml) supplies legends for the aliases its
  parser can't read. [58ba1b1](https://github.com/HefKer/dots/commit/58ba1b1)
