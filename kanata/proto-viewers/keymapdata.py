"""PROTOTYPE (hefker/dots-issues#54), throwaway: the data every keymap viewer prototype shares.

keymap() -> {layers: [{name, keys: [key]}], geometry: [{x, y, w, h}]}, where each key has
  pos, src (defsrc name), raw (the kbd action, "" if the layer leaves it unmapped),
  t/s/h (keymap-drawer's tap/shifted/hold legends), held (the layer's activation key),
  inherited (unmapped: falls through to defsrc), search (lowercased text a query matches).
theme() -> DMS's matugen palette for the current mode, mapped to keymap roles.
draw_svg(out, layers) -> keymap-drawer's SVG, themed through draw_config.

keymap-drawer and the 60% layout come from the installed kanata-keymap-render, so the
prototypes draw exactly what Mod+/ draws today.
"""

import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
KANATA = HERE.parent
KBD = KANATA / "keymap.kbd"
DRAWER_YAML = KANATA / "keymap-drawer.yaml"
DMS_COLORS = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "DankMaterialShell/dms-colors.json"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "kanata-keymap-proto"

# keymap-drawer's 60% places keys by name, in this order.
CANON = (
    "grv 1 2 3 4 5 6 7 8 9 0 - = bspc "
    "tab q w e r t y u i o p [ ] \\ "
    "caps a s d f g h j k l ; ' ret "
    "lsft z x c v b n m , . / rsft "
    "lctl lmet lalt spc ralt rmet menu rctl"
).split()
# The render script's renames (Wooting vs 60%), applied to every key name.
RENAME = {"esc": "grv", "rctl": "rmet", "rmet": "rctl"}


def _tools():
    render = shutil.which("kanata-keymap-render")
    text = Path(os.path.realpath(render)).read_text()
    drawer = re.search(r"/nix/store/[^:\"' ]*keymap-drawer[^:\"'/ ]*", text).group(0)
    layout = re.search(r"/nix/store/[^:\"' ]*info\.json", text).group(0)
    return drawer + "/bin/keymap", layout


def swayimg():
    """swayimg isn't on PATH; the installed viewer script names it."""
    text = Path(os.path.realpath(shutil.which("kanata-keymap"))).read_text()
    return re.search(r"/nix/store/[^:\"' ]*-swayimg-[^:\"'/ ]*", text).group(0) + "/bin/swayimg"


def _drawing_kbd():
    """keymap.kbd with the render script's sed renames, for keymap-drawer's parser."""
    out = []
    for line in KBD.read_text().splitlines():
        line = re.sub(r"^(\s*)esc (\s*[^ (])", r"\1grv \2", line)
        line = re.sub(r"(^|  )rctl ", r"\1@swap@ ", line)
        line = re.sub(r"(^|  )rmet ", r"\1rctl ", line)
        out.append(line.replace("@swap@", "rmet"))
    return "\n".join(out) + "\n"


# --- a tiny s-expression reader for keymap.kbd -------------------------------------------

def _tokens(text):
    text = re.sub(r";;.*", "", text)
    return re.findall(r'\(|\)|"[^"]*"|[^\s()]+', text)


def _read(tokens):
    stack = [[]]
    for tok in tokens:
        if tok == "(":
            stack.append([])
        elif tok == ")":
            done = stack.pop()
            stack[-1].append(done)
        else:
            stack[-1].append(tok)
    return stack[0]


def _flat(x):
    return x if isinstance(x, str) else "(" + " ".join(_flat(y) for y in x) + ")"


def _kbd():
    forms = _read(_tokens(KBD.read_text()))
    src, layers, aliases = [], {}, {}
    for f in forms:
        if not isinstance(f, list) or not f:
            continue
        if f[0] == "defsrc":
            src = f[1:]
        elif f[0] == "defalias":
            for k, v in zip(f[1::2], f[2::2]):
                aliases[k] = _flat(v)
        elif f[0] == "deflayermap":
            name = f[1][0]
            body = f[2:]
            layers[name] = {k: _flat(v) for k, v in zip(body[::2], body[1::2])}
    return src, layers, aliases


def _legend(v):
    if isinstance(v, dict):
        return v
    return {"t": v} if v else {}


def _build():
    drawer, layout = _tools()
    with tempfile.TemporaryDirectory() as tmp:
        kbd = Path(tmp) / "keymap.kbd"
        kbd.write_text(_drawing_kbd())
        yml = Path(tmp) / "keymap.yaml"
        subprocess.run([drawer, "-c", DRAWER_YAML, "parse", "-k", kbd, "-o", yml], check=True)
        parsed = json.loads(subprocess.run(["yq", ".", yml], check=True, capture_output=True, text=True).stdout)
    geometry = [
        {"x": k["x"], "y": k["y"], "w": k.get("w", 1), "h": k.get("h", 1)}
        for k in json.loads(Path(layout).read_text())["layouts"]["LAYOUT_60_ansi"]["layout"]
    ]
    src, kbd_layers, aliases = _kbd()
    pos_of = {name: CANON.index(RENAME.get(name, name)) for name in src}
    name_at = {p: n for n, p in pos_of.items()}
    layers = []
    for lname, legends in parsed["layers"].items():
        mapped = kbd_layers.get(lname, {})
        keys = []
        for pos, v in enumerate(legends):
            leg = _legend(v)
            sname = name_at.get(pos, CANON[pos])
            raw = mapped.get(sname, "")
            held = leg.get("type") == "held"
            inherited = not raw and not held
            words = [leg.get("t", ""), leg.get("s", ""), leg.get("h", ""), raw]
            if raw.startswith("@"):
                words += [raw[1:], aliases.get(raw[1:], "")]
            if inherited:
                words.append(sname)
            keys.append({
                "pos": pos, "src": sname, "raw": raw,
                "t": str(leg.get("t", "")) if not inherited else sname,
                "s": str(leg.get("s", "")), "h": str(leg.get("h", "")),
                "held": held, "inherited": inherited,
                "search": " ".join(str(w) for w in words if w).lower(),
            })
        layers.append({"name": lname, "keys": keys})
    return {"layers": layers, "geometry": geometry}


def keymap():
    """Cached on the inputs' mtimes; a rebuild takes keymap-drawer's ~1 s."""
    stamp = f"{KBD.stat().st_mtime_ns}-{DRAWER_YAML.stat().st_mtime_ns}"
    cache = CACHE / "keymap.json"
    try:
        data = json.loads(cache.read_text())
        if data.get("stamp") == stamp:
            return data
    except (OSError, ValueError):
        pass
    data = _build() | {"stamp": stamp}
    CACHE.mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(data))
    return data


def search(data, query):
    """Every (layer, key) whose legend, action or alias contains the query, as substrings
    of whole words first: "esc" hits Esc, @esc and @cap's tap, not "desc"."""
    q = query.lower().strip()
    if not q:
        return []
    pat = re.compile(r"(^|[^a-z0-9])" + re.escape(q))
    return [(l["name"], k) for l in data["layers"] for k in l["keys"] if pat.search(k["search"])]


def theme_stamp():
    try:
        return DMS_COLORS.stat().st_mtime_ns
    except OSError:
        return 0


def _mix(a, b, t):
    pa = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    pb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(pa, pb))


def theme():
    """Keymap roles from DMS's matugen palette; a fallback dark palette if DMS isn't running."""
    try:
        dms = json.loads(DMS_COLORS.read_text())
        c = dms["colors"][dms.get("mode", "dark")]
    except (OSError, ValueError, KeyError):
        c = {}
    g = lambda k, d: c.get(k, d)
    key, sub = g("surface_container_high", "#2b2930"), g("on_surface_variant", "#cac4d0")
    return {
        "bg": g("surface", "#1d1b20"),
        "key": key,
        "border": g("outline", "#938f99"),
        "legend": g("on_surface", "#e6e0e9"),
        "sub": sub,
        # Halfway between the key fill and its secondary text: an unmapped key, readable but quiet.
        "dim": _mix(key, sub, 0.45),
        "held": g("primary_container", "#4f378b"),
        "on_held": g("on_primary_container", "#eaddff"),
        "hit": g("tertiary", "#efb8c8"),
        "on_hit": g("on_tertiary", "#492532"),
        "accent": g("primary", "#d0bcff"),
    }


def draw_svg(out, layers=None):
    """keymap-drawer's SVG, colored by the current theme."""
    drawer, layout = _tools()
    th = theme()
    style = f"""
svg.keymap {{ background-color: {th['bg']}; }}
rect.key {{ fill: {th['key']}; stroke: {th['border']}; }}
rect.held, rect.combo.held {{ fill: {th['held']}; }}
text {{ fill: {th['legend']}; }}
text.held {{ fill: {th['on_held']}; }}
text.hold, text.shifted, text.left, text.right {{ fill: {th['sub']}; }}
text.label {{ fill: {th['accent']}; stroke: {th['bg']}; }}
"""
    conf = json.loads(subprocess.run(["yq", ".", DRAWER_YAML], check=True, capture_output=True, text=True).stdout)
    conf["draw_config"] = {"svg_extra_style": style, "dark_mode": False}
    with tempfile.TemporaryDirectory() as tmp:
        cfg = Path(tmp) / "config.yaml"
        cfg.write_text(json.dumps(conf))  # JSON is YAML
        kbd = Path(tmp) / "keymap.kbd"
        kbd.write_text(_drawing_kbd())
        yml = Path(tmp) / "keymap.yaml"
        subprocess.run([drawer, "-c", cfg, "parse", "-k", kbd, "-o", yml], check=True)
        cmd = [drawer, "-c", cfg, "draw", "-j", layout, yml, "-o", out]
        if layers:
            cmd += ["-s", *layers]
        subprocess.run(cmd, check=True)
