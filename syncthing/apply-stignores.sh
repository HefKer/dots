#!/usr/bin/env bash
# Per-host Syncthing ignore bootstrap.
#
# Syncthing never syncs .stignore (it's a control file), and symlink sync is
# unreliable, so each host must (re)create ignore wiring locally. This script:
#   1. finds every Syncthing folder root (marked by a .stfolder dir)
#   2. ensures a .stglobalignore symlink -> ~/dots/syncthing/.stglobalignore
#   3. in ~/.claude, also ensures .claudeignore -> ~/dots/syncthing/.claudeignore
#   4. if the root has no .stignore, writes one that #includes whichever of
#      .stglobalignore / .claudeignore / .globalignore exist in that root
#
# Idempotent: never overwrites an existing .stignore, never clobbers symlinks.
set -euo pipefail

DOTS="${DOTS:-$HOME/dots}"
GLOBAL_SRC="$DOTS/syncthing/.stglobalignore"
CLAUDE_SRC="$DOTS/syncthing/.claudeignore"

[ -f "$GLOBAL_SRC" ] || { echo "missing $GLOBAL_SRC — is dots synced?" >&2; exit 1; }

# Find folder roots via the .stfolder marker (dir or file, depending on version).
mapfile -t ROOTS < <(find "$HOME" -maxdepth 6 -name .stfolder -printf '%h\n' 2>/dev/null | sort -u)

[ "${#ROOTS[@]}" -gt 0 ] || { echo "no .stfolder markers found under $HOME" >&2; exit 1; }

for R in "${ROOTS[@]}"; do
  echo "== $R"

  # (1) .stglobalignore symlink
  gi="$R/.stglobalignore"
  if [ ! -e "$gi" ] && [ ! -L "$gi" ]; then
    if [ "$R" = "$DOTS" ]; then
      ln -s "syncthing/.stglobalignore" "$gi"     # relative: travels with dots
    else
      ln -s "$GLOBAL_SRC" "$gi"                    # absolute: same path per host
    fi
    echo "   + .stglobalignore symlink"
  fi

  # (2) .claudeignore symlink — only in ~/.claude
  if [ "$R" = "$HOME/.claude" ]; then
    ci="$R/.claudeignore"
    if [ ! -e "$ci" ] && [ ! -L "$ci" ]; then
      ln -s "$CLAUDE_SRC" "$ci"
      echo "   + .claudeignore symlink"
    fi
  fi

  # (3) .stignore — create only if absent; inherit whatever exists in this root
  si="$R/.stignore"
  if [ ! -f "$si" ]; then
    {
      echo '#include .stglobalignore'
      [ -e "$R/.claudeignore" ] && echo '#include .claudeignore'
      [ -e "$R/.globalignore" ] && echo '#include .globalignore'
    } > "$si"
    echo "   + .stignore ($(tr '\n' ' ' < "$si"))"
  else
    echo "   . .stignore exists — left as-is"
  fi
done

echo
echo "Done. Rescan each folder in the Syncthing UI (or restart the daemon)."
