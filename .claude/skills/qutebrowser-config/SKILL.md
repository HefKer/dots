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
- `cs` → re-source the config without restarting the browser

Prefer `cs` over telling the user to restart.

## Don't hand-edit

`autoconfig.yml` is state written by qutebrowser's own GUI/`:set` commands, and is gitignored. Changes belong in the Python config modules so they survive.

## Removing a keybind

Deleting a `config.bind()` line doesn't unbind the key — `cs` only applies what's in the file now, it doesn't diff against what a prior run left bound. The key stays live until explicitly unbound. So removal is two turns:

1. Delete the `config.bind()` line and add `config.unbind("key")` in its place. Tell the user to `cs`.
2. Once they confirm the `cs`, delete the `config.unbind()` line too — its job is done, and leaving it in is dead weight on every future `cs`.

## Editor integration

`<Ctrl-e>` opens the external editor: wezterm running nvim.
