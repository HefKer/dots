---
name: herdr-config
description: Edit the herdr config in this dotfiles repo (herdr/.config/herdr/config.toml) — what is safe to stow, how to apply changes to a running server, and how to validate them. Use when editing herdr's config.toml, adding or changing herdr keybindings, or stowing/restowing the herdr package. Not for driving herdr itself (that is the vendor `herdr` skill).
---

# herdr config (dots)

## Stow safety

Only `config.toml` is stowed. `~/.config/herdr/` is also herdr's **runtime state directory** — it holds `*.sock`, `*.log`, `session.json`, `release-notes.json`.

**Never stow the whole `~/.config/herdr/` dir.** Add individual files to `herdr/.config/herdr/` in this repo instead.

## Upgrading herdr

herdr is packaged in NixOS — upgrade it in `~/nixos/`. Do **not** use the upstream `curl | sh` installer; it will fight the Nix-managed binary.

## Applying and validating config changes

Apply edits to a running server with:

```sh
herdr server reload-config
```

Read the JSON `diagnostics` array in its output — that is the real validator. `herdr config check` will catch unknown keys but **not** invalid values, so a config that passes `config check` can still be wrong.

## Key syntax gotchas

Verify these against the installed herdr version before relying on them — the schema has changed across releases.

- The config table for bindings has been `[keys]`, not `[keybindings]`.
- The pipe binding is written as the literal `prefix+|`.
- `navigate_pane_*` bindings omit the `prefix` component.

If a binding silently does nothing after a reload, check `diagnostics` first, then re-read herdr's own docs for the current key schema.
