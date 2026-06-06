# syncthing

Single-source `.stglobalignore` shared across all Syncthing folders on all hosts.

## Why not stow

Syncthing's `#include` directive resolves **relative to the folder root** — absolute
paths and `~` are not supported. Stowing to `~/.stglobalignore` wouldn't help; each
folder still needs the file reachable by a relative path. Instead, every Syncthing
folder root gets a symlink named `.stglobalignore` pointing at this file, and the
folder's `.stignore` does `#include .stglobalignore`.

## Per-host setup

Assumes `~/dots` is cloned on the host. For each Syncthing folder root `<DIR>`:

1. Symlink the global file into the folder root:

   ```sh
   ln -s ~/dots/syncthing/.stglobalignore <DIR>/.stglobalignore
   ```

   Exception — when `<DIR>` is `~/dots` itself, use a **relative** target so the
   link travels with the synced tree:

   ```sh
   ln -s syncthing/.stglobalignore ~/dots/.stglobalignore
   ```

2. Add the include line at the top of `<DIR>/.stignore`:

   ```
   #include .stglobalignore
   ```

   Keep any existing per-folder include (e.g. `#include .globalignore`) below it.
   First-match-wins, so order matters if a folder rule needs to override a global
   one.

3. Reload ignores in Syncthing UI (folder → Actions → Rescan) or restart the
   daemon. Verify the expanded patterns under folder → Edit → Ignore Patterns.

## Editing `.stglobalignore`

Edit `~/dots/syncthing/.stglobalignore` directly. Commit + push from any host;
other hosts pick it up on `git pull`. No symlink retargeting needed.

## Removing from a host

```sh
rm <DIR>/.stglobalignore
# then drop the `#include .stglobalignore` line from <DIR>/.stignore
```
