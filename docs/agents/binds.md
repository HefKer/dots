# Binds

How to choose a bind, for any scope: remapper, window manager, shell,
multiplexer, app. Terms (**Rung**, **Group**, **Overlap**, **Alias**, …) are
defined in `GLOSSARY.md`; the remapper's in `~/nixos/main/GLOSSARY.md`.

## Before proposing a bind

Answer each of these in the proposal itself. A bind is ready when every one has
an answer:

1. **Rung**: how often the action is used, and whether it is needed mid-task.
   That decides its rung (below).
2. **Scope**: which scope owns it. Shell binds belong to DMS (ADR 0003).
3. **Grammar**: its group letter, or its modifiers, checked against the
   dictionaries below.
4. **Overlap**: checked against the live binds, not memory:
   `dms keybinds show niri`, qutebrowser's `:bind`, nvim's `<leader>sk`,
   `kanata/keymap.kbd`, herdr's `config.toml`.
5. **Hints**: a sequence lives only in a scope that shows what can follow.
6. **Search**: the action stays reachable by search, bound or not.

## Rungs

| Rung | Trigger | Earned by |
|---|---|---|
| 1 | combo or chord | several times an hour, or needed mid-task |
| 2 | mnemonic sequence | daily or weekly |
| 3 | search: launcher, `:` command, palette, settings search | everything: this is the floor |
| 4 | menu | only on top of rung 3 |

Monthly or rarer stays on rung 3, unless the mnemonic is so obvious it costs
nothing to remember. A cheap rung goes to the frequent action; a rare one moves
down to make room.

## Grammar

**Sequences are group-first** (ADR 0002): the first letter names a domain, and
what follows names the target within it (`e b h`: external → browser →
helium). Under a leader, LazyVim's leader groups are the dictionary (`f` find, `g` git, `s`
search, `q` session, `b` buffer, `u` UI, `x` diagnostics). Other scopes use the
same letter for the same domain, and claim a new letter only for a domain
LazyVim lacks (`e` external, `m` memes and sounds, `o` outputs). A bare prefix,
with no leader before it, follows the app's own convention (qutebrowser's `g`
go, `;` hint, `c` config) plus `e` external.

**Each modifier carries one meaning per scope.** In the window manager:

- `Mod`: go to, or do
- `+Ctrl`: move the thing
- `+Shift`: the other target or axis: a wider one (monitor rather than column,
  all rather than one, fullscreen rather than maximized) or its counterpart
  (window height beside column width, floating beside tiling)
- `+Alt`: apps (summon)

A different action, such as *add* beside *pick*, gets its own key or a leader
sequence, not a modifier variant.

**A leader one scope up is the same trigger plus `Mod`.** herdr's prefix is
`Ctrl+Space`, so the desktop leader is `Mod+Ctrl+Space`: the one stated
exception to `+Ctrl` meaning move. It holds rare desktop actions, and app
actions reachable over the app's IPC.

## Overlaps

An overlap is a bug to fix; a typed command sharing letters with a sequence
(the shell's `cd`) is not one. Aliases follow the same rule: one alias names
one target in every scope that takes aliases, the more-used target keeps it,
and the other gets a suffix (`yt`, `ytm`).

## Conventions, mouse, timing

- **Platform conventions** (`Ctrl+C/V/W/T`, `Ctrl+K` palette, `Ctrl+,`
  settings, `Ctrl+F` find) hold in apps that aren't heavily customised, and in
  the insert and edit modes of modal ones. Normal mode belongs to the grammar
  above.
- **Mouse** is for spatial or continuous work: dragging, region select,
  scrubbing. Every discrete action also has a keyboard or search path; hints
  (qutebrowser's `f`, `window-pick`) stand in for clicking.
- **Timing triggers** (tap-hold, double-tap) live only in the remapper, on keys
  where a misfire is cheap and undoable. Destructive actions get a plain
  trigger.
