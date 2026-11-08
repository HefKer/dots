#!/bin/bash
# Desktop notification on Claude Code events, via the freedesktop Notifications
# DBus service (DankMaterialShell provides it). Wired for Stop + Notification.
# Reads the hook JSON payload on stdin.

INPUT=$(cat)

EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
CWD=$(printf '%s'   "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
MSG=$(printf '%s'   "$INPUT" | jq -r '.message // empty' 2>/dev/null)
TP=$(printf '%s'    "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# Which conversation: dir basename + Claude's generated title.
DIR=$([ -n "$CWD" ] && basename "$CWD" || echo "claude")
TOPIC=""
if [ -n "$TP" ] && [ -f "$TP" ]; then
  TOPIC=$(grep '"type":"ai-title"' "$TP" 2>/dev/null | jq -r '.aiTitle' 2>/dev/null | tail -1)
fi

case "$EVENT" in
  Notification)
    SUMMARY="Claude needs you — $DIR"
    BODY="${MSG:-Waiting for input}"
    ICON="dialog-warning"
    ;;
  Stop|SubagentStop)
    SUMMARY="Claude done — $DIR"
    BODY="${TOPIC:-Turn complete}"
    ICON="dialog-information"
    ;;
  *)
    SUMMARY="Claude — $DIR"
    BODY="${TOPIC:-$EVENT}"
    ICON="dialog-information"
    ;;
esac

gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  "Claude Code" 0 "$ICON" "$SUMMARY" "$BODY" "[]" "{}" 6000 >/dev/null 2>&1

exit 0
