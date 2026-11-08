#!/bin/bash
# Rejects `pkill -f <pattern>`: the pattern also matches the shell running it, so
# the shell kills itself (exit 144). A bracketed pattern can't match itself.
# Wired for PreToolUse on Bash. Reads the hook JSON payload on stdin.

CMD=$(jq -r '.tool_input.command // empty' 2>/dev/null)

if printf '%s\n' "$CMD" \
  | grep -E '(^|[;&|(]|sudo)[[:space:]]*pkill\b[^;&|]*[[:space:]](-[a-zA-Z]*f|--full)\b' \
  | grep -qv '\['; then
  echo "Blocked: pkill -f matches this shell's own command line and kills it (exit 144). Bracket one character of the pattern, e.g. pkill -f '[b]asedir /tmp/x', or kill a recorded PID." >&2
  exit 2
fi
exit 0
