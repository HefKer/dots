#!/usr/bin/env python3
"""Print the fenced code blocks of the Claude Code session in herdr's focused pane.

Called by wezterm's quick select with the argv of the herdr client running in
the wezterm pane. Claude Code renders code blocks without fences and wraps them
at the pane edge, so the screen can't say where a block starts or ends, but the
session transcript keeps the markdown as written.

Prints a JSON list of blocks, newest first, and an empty list on any failure.
"""

import glob
import json
import os
import re
import subprocess
import sys

FENCE = re.compile(r"^( *)(`{3,}|~{3,})[^\n]*\n(.*?)^ *\2[ \t]*$", re.S | re.M)


def socket_path(argv):
    """The socket of the herdr server the client was started for, or None."""
    args = argv[1:]
    if any(a in ("--remote", "--machine") for a in args):
        return None
    session = None
    if "--session" in args:
        session = args[args.index("--session") + 1]
    elif args[:2] == ["session", "attach"] and len(args) > 2:
        session = args[2]
    root = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "herdr")
    if session:
        return os.path.join(root, "sessions", session, "herdr.sock")
    return os.path.join(root, "herdr.sock")


def claude_session(sock):
    out = subprocess.run(
        ["herdr", "pane", "current"],
        env={**os.environ, "HERDR_SOCKET_PATH": sock},
        capture_output=True,
        text=True,
        timeout=2,
    ).stdout
    pane = json.loads(out)["result"]["pane"]
    session = pane.get("agent_session") or {}
    if pane.get("agent") != "claude" or session.get("kind") != "id":
        return None
    return session["value"]


def blocks(transcript):
    found = []
    with open(transcript) as f:
        for line in f:
            # Skip the json parse for the many lines that can't hold a block.
            if "```" not in line and "~~~" not in line:
                continue
            msg = json.loads(line)
            if msg.get("type") != "assistant":
                continue
            for part in msg["message"].get("content", []):
                if part.get("type") != "text":
                    continue
                for indent, _, body in FENCE.findall(part["text"]):
                    # A fence inside a list item is indented, and so is its body.
                    lines = [l[len(indent):] if l.startswith(indent) else l for l in body.split("\n")]
                    block = "\n".join(lines).rstrip("\n")
                    if block.strip():
                        found.append(block)
    seen, newest_first = set(), []
    for block in reversed(found):
        if block not in seen:
            seen.add(block)
            newest_first.append(block)
    return newest_first


def main():
    sock = socket_path(sys.argv[1:])
    session = sock and claude_session(sock)
    if not session:
        return []
    homes = glob.glob(os.path.expanduser("~/.claude*/projects/*/" + session + ".jsonl"))
    if not homes:
        return []
    return blocks(max(homes, key=os.path.getmtime))


if __name__ == "__main__":
    try:
        result = main()
    except Exception:
        result = []
    print(json.dumps(result))
