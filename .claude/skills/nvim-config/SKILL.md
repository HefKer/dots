---
name: nvim-config
description: Conventions for editing the nvim package in this dotfiles repo, which is a LazyVim distro. Use when adding or configuring Neovim plugins, keymaps, or options.
---

# nvim config (dots)

This is a **LazyVim** distro, not a from-scratch config.

## Don't reinvent what LazyVim provides

Before adding a plugin, keymap, or autocmd, check whether LazyVim already ships it. LazyVim bundles LSP, formatting, completion, pickers, statusline, and a large keymap set. Adding a competing plugin or re-binding something LazyVim owns causes conflicts that are hard to trace.

Prefer extending or overriding LazyVim's spec over replacing it — return a plugin spec table with `opts` that merge, rather than re-declaring the plugin wholesale.

## Where things go

- User plugin specs → `lua/plugins/*.lua`
- Options, keymaps, autocmds → `lua/config/`

## Lockfile and formatting

- `lazy-lock.json` is committed. Run `:Lazy sync` to update it, and commit the result alongside the change.
- Lua is formatted with `stylua` (`stylua.toml` at the package root).
