---
name: fish-config
description: Conventions for editing the fish package in this dotfiles repo — which conf.d file owns a change, startup guards, and autoload vs eager definitions. Use when changing fish abbreviations, aliases, key bindings, functions, or shell startup.
---

# fish config (dots)

## Edit the right file

`config.fish` is a map, not a config — it holds only a comment listing what each `conf.d` file owns. Read it to pick the file, then edit that file. Fish sources `conf.d/*.fish` itself in filename order, so a new file needs no registering.

Standalone commands are autoloaded one-per-file from `functions/`.

## Every conf.d file guards its contents

`conf.d` is sourced by every fish, scripts included, so each file states which shells its contents are for.

A file with one audience opens with a single guard:

```fish
status is-interactive || exit 0
```

That `exit` ends only the file it sits in — later `conf.d` files still load.

A file whose contents split across audiences uses `if` blocks instead, one per audience, as `00-env.fish` does. Exports every shell wants (`MANPAGER`, `PATH` additions) sit outside the blocks.

A tool that installs itself by sourcing generated code (`atuin init fish | source`) defines functions and bindings, which child shells don't inherit, so it belongs in `10-tools.fish` under the interactive guard. `status is-login` would miss herdr panes, which are non-login. NixOS already loads zoxide, starship and direnv from `/etc/fish/config.fish` in every interactive shell, so don't add those here. A tool NixOS doesn't load goes in `10-tools.fish`; one it can load is better enabled in `~/nixos/`.

## Autoload vs eager

A function in `functions/` is autoloaded on first call. That is the normal home for a command.

An event handler is the exception: fish does not autoload a function just because its event fired. Anything carrying `--on-variable` or `--on-event` must be defined eagerly, which is what `50-hooks.fish` is for.

## Abbreviation or alias

Reach for `abbr` by default. It expands in place, so the command stays editable before it runs and history records what actually ran.

Use `alias` for a wrapper that should stay unexpanded — a command with flags baked in that you always want applied (`ls`, `lt`).

## Reload

`exec fish` replaces the running shell and picks up everything.

## Don't hand-edit

`fish_variables` is fish's universal-variable store, rewritten at runtime. It is gitignored and untracked — anything worth keeping goes in `conf.d`.
