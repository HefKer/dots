"""Clickable desktop notifications for agents that finish or block while you look elsewhere.

`event` runs on herdr's pane.agent_status_changed hook and hands off to a detached
`notify`, since the notification waits for a click and the hook must return. Clicking
focuses the agent in herdr, the terminal tab running the herdr client (wezterm), and
that terminal's niri window.
"""

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

SOCKET = os.environ.get("HERDR_SOCKET_PATH", "")
STATE = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR", "/tmp/herdr-agent-notify"))
STATUSES = {"done": "finished", "blocked": "needs you"}
# Matches herdr's [ui.toast] delay_seconds default: a status that flips straight back stays quiet.
DELAY = 1


def request(method, params):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(2)
        client.connect(SOCKET)
        client.sendall((json.dumps({"id": "agent-notify", "method": method, "params": params}) + "\n").encode())
        reply = b""
        while not reply.endswith(b"\n"):
            chunk = client.recv(1 << 20)
            if not chunk:
                break
            reply += chunk
    response = json.loads(reply)
    if "error" in response:
        sys.exit(f"agent-notify: {method}: {response['error']}")
    return response["result"]


def snapshot():
    result = request("session.snapshot", {})
    return result.get("snapshot", result)


def session_name():
    """herdr.sock sits in ~/.config/herdr for the default session, sessions/<name>/ otherwise."""
    parent = Path(SOCKET).parent
    return parent.name if parent.parent.name == "sessions" else "default"


def proc_env(pid):
    try:
        raw = Path(f"/proc/{pid}/environ").read_bytes()
    except OSError:
        return {}
    return dict(item.split("=", 1) for item in raw.decode(errors="replace").split("\0") if "=" in item)


def ppid(pid):
    try:
        stat = Path(f"/proc/{pid}/stat").read_text()
    except OSError:
        return 0
    return int(stat.rsplit(")", 1)[1].split()[1])


def clients():
    """Pids of herdr clients attached to this plugin's session."""
    name = session_name()
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv = (entry / "cmdline").read_bytes().decode(errors="replace").split("\0")[:-1]
        except OSError:
            continue
        if not argv or os.path.basename(argv[0]) != "herdr":
            continue
        args = argv[1:]
        if args in ([], ["--session", "default"]) and name == "default":
            yield int(entry.name)
        elif args in (["--session", name], ["session", "attach", name]):
            yield int(entry.name)


def niri_windows():
    try:
        out = subprocess.run(["niri", "msg", "-j", "windows"], capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return []
    return json.loads(out)


def terminal_window(client, windows):
    """The niri window of the terminal running client, found by walking up its parents."""
    by_pid = {}
    for window in windows:
        by_pid.setdefault(window["pid"], []).append(window)
    pid = client
    while pid > 1 and pid not in by_pid:
        pid = ppid(pid)
    candidates = by_pid.get(pid, [])
    if len(candidates) > 1:
        # One wezterm process draws every window; its title names the active tab.
        title = wezterm_title(client)
        candidates = [w for w in candidates if title and title in (w.get("title") or "")] or candidates
    return candidates[0] if candidates else None


def wezterm(client, *args):
    env = proc_env(client)
    if "WEZTERM_PANE" not in env:
        return None
    run_env = dict(os.environ, WEZTERM_UNIX_SOCKET=env.get("WEZTERM_UNIX_SOCKET", ""))
    try:
        return subprocess.run(["wezterm", "cli", *args], env=run_env, capture_output=True, text=True, timeout=3)
    except (OSError, subprocess.TimeoutExpired):
        return None


def wezterm_title(client):
    pane = proc_env(client).get("WEZTERM_PANE")
    listing = wezterm(client, "list", "--format", "json")
    if not pane or not listing or listing.returncode:
        return None
    for entry in json.loads(listing.stdout):
        if str(entry["pane_id"]) == pane:
            return entry["title"]
    return None


def in_view(pane_id, snap):
    """Whether herdr's focus is on the agent or on its tab's prompt pane, zoomed over it."""
    focused = snap.get("focused_pane_id")
    if focused == pane_id:
        return True
    pane = next((p for p in snap["panes"] if p["pane_id"] == focused), None)
    agent = next((p for p in snap["panes"] if p["pane_id"] == pane_id), None)
    return bool(pane and agent and pane.get("label") == "prompt" and pane["tab_id"] == agent["tab_id"])


def watching(pane_id, snap):
    """Whether the agent is in view in herdr, shown in the focused terminal window."""
    if not in_view(pane_id, snap):
        return False
    windows = niri_windows()
    focused = next((w for w in windows if w.get("is_focused")), None)
    if focused is None:
        return False
    for client in clients():
        window = terminal_window(client, windows)
        if window and window["id"] == focused["id"]:
            listing = wezterm(client, "list-clients", "--format", "json")
            if listing is None or listing.returncode:
                return True  # Not wezterm: the window being focused is the best signal there is.
            pane = proc_env(client)["WEZTERM_PANE"]
            if any(str(c.get("focused_pane_id")) == pane for c in json.loads(listing.stdout)):
                return True
    return False


def show(client):
    """Bring the terminal running client to the front, on the tab holding it."""
    wezterm(client, "activate-pane", "--pane-id", proc_env(client).get("WEZTERM_PANE", ""))
    window = terminal_window(client, niri_windows())
    if window:
        subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(window["id"])], check=False)


def open_agent(pane_id):
    """Focus the agent; a Claude waiting for its next prompt gets the nvim prompt pane.

    A blocked Claude is asking a question or for a tool permission, which only its own
    pane answers, so that one gets the agent pane itself.
    """
    snap = snapshot()
    agent = next((a for a in snap["agents"] if a["pane_id"] == pane_id), None)
    if agent is None or agent.get("agent") != "claude" or agent["agent_status"] not in ("done", "idle"):
        request("agent.focus", {"target": pane_id})
        return
    # scripts/claude-prompt labels its pane "prompt"; reuse one already open in the tab.
    prompt = next(
        (p for p in snap["panes"] if p["tab_id"] == agent["tab_id"] and p.get("label") == "prompt"),
        None,
    )
    if prompt:
        request("pane.focus", {"pane_id": prompt["pane_id"]})
        herdr("pane", "zoom", prompt["pane_id"], "--on")
        return
    request("agent.focus", {"target": pane_id})
    env = dict(os.environ, HERDR_ACTIVE_PANE_ID=pane_id)
    subprocess.run([str(Path.home() / "dots/scripts/claude-prompt")], env=env, capture_output=True, check=False)


def herdr(*args):
    """The herdr CLI, which reaches this plugin's session through HERDR_SOCKET_PATH."""
    binary = os.environ.get("HERDR_BIN_PATH", "herdr")
    subprocess.run([binary, *args], capture_output=True, check=False)


def notify(pane_id, status):
    time.sleep(DELAY)
    snap = snapshot()
    agent = next((a for a in snap["agents"] if a["pane_id"] == pane_id), None)
    if agent is None or agent["agent_status"] != status or watching(pane_id, snap):
        return
    workspace = next((w["label"] for w in snap["workspaces"] if w["workspace_id"] == agent["workspace_id"]), "")
    tab = next((t["label"] for t in snap["tabs"] if t["tab_id"] == agent["tab_id"]), "")
    title = f"{agent.get('agent') or 'agent'} {STATUSES[status]}"
    body = "\n".join(filter(None, [agent.get("terminal_title_stripped"), " · ".join(filter(None, [workspace, tab]))]))

    # One notification per pane: a newer status replaces the last one instead of stacking.
    STATE.mkdir(parents=True, exist_ok=True)
    id_file = STATE / (pane_id.replace(":", "_") + ".id")
    command = ["notify-send", "--app-name=Herdr", "--print-id", "--action=default=Show", title, body]
    if id_file.exists():
        command[1:1] = ["--replace-id", id_file.read_text().strip()]
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, text=True)
    assert proc.stdout
    id_file.write_text(proc.stdout.readline().strip())
    action = proc.stdout.read().strip()
    proc.wait()
    if action != "default":
        return
    open_agent(pane_id)
    for client in clients():
        show(client)
        break


def main():
    if sys.argv[1:2] == ["event"]:
        event = json.loads(os.environ.get("HERDR_PLUGIN_EVENT_JSON", "{}"))
        data = event.get("data", event)
        status = data.get("agent_status")
        if status in STATUSES and data.get("pane_id"):
            subprocess.Popen(
                [sys.executable, __file__, "notify", data["pane_id"], status],
                start_new_session=True,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
    elif sys.argv[1:2] == ["notify"]:
        notify(*sys.argv[2:4])
    else:
        sys.exit("usage: agent-notify.py event|notify <pane> <status>")


if __name__ == "__main__":
    main()
