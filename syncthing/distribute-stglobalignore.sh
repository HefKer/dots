#!/usr/bin/env bash
# Materialize every symlinked Syncthing ignore *include* file as a REAL file at
# its folder root.
#
# WHY: Syncthing v2.1.2 rejects symlinked include files with
#   "loading ignores: parse error: failed to load include file
#    <name>: ... too many levels of symbolic links"
# It's a regression (side effect of a security fix), acknowledged upstream.
# Once a fixed release ships, revert the folder roots back to symlinks and
# retire this script.
#
# What it does: for each folder, scans its .stignore for `#include <name>`
# lines; if <root>/<name> is a symlink, replaces it with a real copy of the
# symlink's target (the shared masters live in ~/dots/syncthing/). Idempotent —
# re-run after editing a master, or on a fresh machine.
#
# Usage: ./distribute-stglobalignore.sh
set -euo pipefail

cfg="${SYNCTHING_CONFIG:-$HOME/.local/state/syncthing/config.xml}"
[ -f "$cfg" ] || cfg="$HOME/.config/syncthing/config.xml"
[ -f "$cfg" ] || { echo "config missing: $cfg" >&2; exit 1; }

paths=$(python3 - "$cfg" <<'PY'
import sys, os, xml.etree.ElementTree as ET
for f in ET.parse(sys.argv[1]).getroot().iter('folder'):
    print(os.path.expanduser(f.get('path') or ''))
PY
)

while IFS= read -r p; do
    [ -n "$p" ] || continue
    sti="$p/.stignore"
    [ -f "$sti" ] || continue
    # Extract include targets: lines like `#include NAME`.
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        dst="$p/$name"
        # Only act on symlinks; leave real files and missing entries alone.
        [ -L "$dst" ] || continue
        src="$(readlink -f "$dst")" || continue
        [ -f "$src" ] || { echo "skip (dangling): $dst" >&2; continue; }
        tmp="$dst.tmp.$$"
        cp -f "$src" "$tmp"
        mv -f "$tmp" "$dst"      # atomic replace; removes the symlink
        echo "materialized $dst -> (copy of $src)"
    done < <(grep -oP '^\s*#include\s+\K.+$' "$sti" || true)
done <<< "$paths"
