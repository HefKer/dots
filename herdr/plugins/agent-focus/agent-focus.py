"""Set or clear the agent view behind herdr-plugin.toml's startup hook and toggle action.

On: the sidebar lists the current space's agents, plus any agent elsewhere that is
blocked or finished unseen (done), so cycling stays in the space you are in unless
something else needs you. Off: herdr's own list of every agent.
"""

import json
import os
import socket
import sys
from pathlib import Path

SOURCE = "plugin:" + os.environ.get("HERDR_PLUGIN_ID", "hefker.agent-focus")
STATE = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR", ".")) / "mode"

VIEW = {
    "source": SOURCE,
    "label": "focus",
    "filter": {
        "op": "any",
        "filters": [
            {"op": "eq", "field": "workspace_id", "value": {"context": "current_workspace_id"}},
            {"op": "in", "field": "status", "values": ["blocked", "done"]},
        ],
    },
}


def request(method, params):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(2)
        client.connect(os.environ["HERDR_SOCKET_PATH"])
        client.sendall((json.dumps({"id": "agent-focus", "method": method, "params": params}) + "\n").encode())
        reply = b""
        while not reply.endswith(b"\n"):
            chunk = client.recv(65536)
            if not chunk:
                break
            reply += chunk
    response = json.loads(reply)
    if "error" in response:
        sys.exit(f"agent-focus: {method}: {response['error']}")


def apply(on):
    if on:
        request("agent.view.set", VIEW)
    else:
        request("agent.view.clear", {"source": SOURCE})


def main():
    on = STATE.exists() and STATE.read_text().strip() == "on"
    if sys.argv[1:] == ["toggle"]:
        on = not on
        STATE.parent.mkdir(parents=True, exist_ok=True)
        STATE.write_text("on\n" if on else "off\n")
    elif sys.argv[1:] != ["restore"]:
        sys.exit("usage: agent-focus.py restore|toggle")
    apply(on)


main()
