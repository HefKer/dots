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

- `lazy-lock.json` is committed. After adding a plugin, run `nvim --headless "+Lazy! install" +qa`: it clones only the new plugin and adds its lock entry. `Lazy sync` also upgrades every other plugin, so use it only when the user asks for upgrades. Commit the lockfile alongside the change.
- Lua is formatted with `stylua` (`stylua.toml` at the package root).

## Verifying

- Installed plugin source lives in `~/.local/share/nvim/lazy/<name>/`. Read it before concluding a plugin lacks a feature or backend — the pinned commit may already ship it.
- LazyVim loads `lua/config/keymaps.lua` and `VeryLazy` specs on an event that never fires under `--headless`, so headless probes report those keymaps as unmapped. Probe under a pty instead, with a script that writes its findings to a file and quits:

  ```sh
  script -qec "nvim -S probe.lua" /dev/null; cat out.txt
  ```

  where `probe.lua` wraps its checks in `vim.defer_fn(function() ... vim.fn.writefile(lines, "out.txt"); vim.cmd("qa!") end, 2000)`.
