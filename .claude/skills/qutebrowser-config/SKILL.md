---
name: qutebrowser-config
description: Conventions for editing the qutebrowser package in this dotfiles repo — which module to edit, how to reload config, and what is GUI-written state. Use when changing qutebrowser settings, keybindings, search engines, or themes.
---

# qutebrowser config (dots)

## Edit the right module

`config.py` is a dispatcher — it `config.source()`s split modules (`appearance`, `privacy`, `filepicker`, `binds`, `search_engines`, …). Make changes in the module that owns the setting; don't pile them into `config.py`.

Themes are a Python package under `themes/`.

## Reload

- `ce` → config-edit
- `cs` → `config-source --clear`: resets every setting and binding to qutebrowser's defaults, then re-runs `config.py`. `config.py` loads `autoconfig.yml` first, so GUI-set settings survive the clear.

Prefer `cs` over telling the user to restart. Keep `--clear` on it: plain `config-source` layers the config onto the live state, so deleted or renamed binds linger until a restart.

## Don't hand-edit

`autoconfig.yml` is state written by qutebrowser's own GUI/`:set` commands, and is gitignored. Changes belong in the Python config modules so they survive.

## Removing a keybind

Because `cs` clears first, it rebuilds bindings from qutebrowser's defaults plus the config as it is now, so the key's default status decides the edit:

- **Custom key** (absent from the defaults): delete its `config.bind()` line; `cs` drops it. `config.unbind()` on such a key errors with `Can't find binding`.
- **Default key overridden by the config** (e.g. `d`, `u`): deleting the line restores qutebrowser's default action.
- **Default key to disable**: keep `config.unbind("key")` in the config permanently.

The defaults are listed under `bindings.default` in `qute://help/settings.html`.

## Editor integration

`<Ctrl-e>` opens the external editor: wezterm running nvim.
