#!/usr/bin/env bash
# Back up ~/.claude.json, but only when it is valid, non-empty JSON.
#
# Why: .claude.json is a single global file that every Claude Code session
# rewrites via truncate-then-write. When several sessions start at the same
# instant (e.g. Herdr relaunching a batch of panes after a server restart),
# the writes collide and the file can be left at 0 bytes, which resets all
# project permissions, trust dialogs, and MCP config.
#
# This hook refuses to overwrite a good backup with a blank or broken file,
# so the rotation always holds recoverable state.
#
# Restore with:  cp ~/.claude.json.bak ~/.claude.json   (with no session running)

set -uo pipefail

CONFIG="$HOME/.claude.json"
BACKUP="$HOME/.claude.json.bak"
KEEP=20

# Nothing to do if the config is missing or already empty.
[ -s "$CONFIG" ] || exit 0

# Only proceed if it parses AND looks like real state rather than a
# post-reset default file. Claude Code's own backup rotation does not make
# this distinction -- a 1093-byte default file landed in it at 14:20 today,
# which is exactly the copy you never want to restore from.
python3 - "$CONFIG" <<'PY' 2>/dev/null || exit 0
import json, sys
d = json.load(open(sys.argv[1]))
assert "oauthAccount" in d, "not logged in - looks like a fresh default"
assert d.get("projects"), "no project state - looks like a fresh default"
PY

# Skip if unchanged, so the rotation isn't churned by every session exit.
if [ -f "$BACKUP" ] && cmp -s "$CONFIG" "$BACKUP"; then
  exit 0
fi

# Rotate: .bak -> .bak.1 -> .bak.2 ...
for ((i = KEEP - 1; i >= 1; i--)); do
  [ -f "$BACKUP.$i" ] && mv -f "$BACKUP.$i" "$BACKUP.$((i + 1))"
done
[ -f "$BACKUP" ] && cp -p "$BACKUP" "$BACKUP.1"

# Write to a temp file in the same directory, then rename, so the backup
# itself is updated atomically and can never be observed half-written.
TMP=$(mktemp "$HOME/.claude.json.bak.XXXXXX") || exit 0
if cp "$CONFIG" "$TMP" && mv -f "$TMP" "$BACKUP"; then
  exit 0
fi
rm -f "$TMP"
exit 0
