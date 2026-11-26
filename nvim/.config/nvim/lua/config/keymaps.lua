-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- smart-splits: move/resize across nvim splits and herdr panes alike.
-- CTRL to move, CTRL+ALT to resize.
local splits = function(fn)
  return function()
    require("smart-splits")[fn]()
  end
end

vim.keymap.set("n", "<C-h>", splits("move_cursor_left"), { desc = "Go to Left Window/Pane" })
vim.keymap.set("n", "<C-j>", splits("move_cursor_down"), { desc = "Go to Lower Window/Pane" })
vim.keymap.set("n", "<C-k>", splits("move_cursor_up"), { desc = "Go to Upper Window/Pane" })
vim.keymap.set("n", "<C-l>", splits("move_cursor_right"), { desc = "Go to Right Window/Pane" })

-- The same from insert mode, leaving it first: arriving in insert in a buffer you
-- can't edit, like the prompt pane's reply viewer, would fail on the first key.
local from_insert = function(fn)
  return function()
    vim.cmd.stopinsert()
    require("smart-splits")[fn]()
  end
end
vim.keymap.set("i", "<C-h>", from_insert("move_cursor_left"), { desc = "Go to Left Window/Pane" })
vim.keymap.set("i", "<C-j>", from_insert("move_cursor_down"), { desc = "Go to Lower Window/Pane" })
vim.keymap.set("i", "<C-k>", from_insert("move_cursor_up"), { desc = "Go to Upper Window/Pane" })
vim.keymap.set("i", "<C-l>", from_insert("move_cursor_right"), { desc = "Go to Right Window/Pane" })

vim.keymap.set("n", "<C-A-h>", splits("resize_left"), { desc = "Resize Window Left" })
vim.keymap.set("n", "<C-A-j>", splits("resize_down"), { desc = "Resize Window Down" })
vim.keymap.set("n", "<C-A-k>", splits("resize_up"), { desc = "Resize Window Up" })
vim.keymap.set("n", "<C-A-l>", splits("resize_right"), { desc = "Resize Window Right" })

-- Rename the current file by its name alone, keeping its directory and extension.
vim.keymap.set("n", "<leader>cR", function()
  require("config.rename").rename(vim.api.nvim_buf_get_name(0))
end, { desc = "Rename File" })

-- Inside an Obsidian vault, a new file is a named note in the folder the app
-- would put it in (polaris: the + inbox); elsewhere it's LazyVim's empty buffer.
vim.keymap.set("n", "<leader>fn", function()
  require("config.obsidian").new_note()
end, { desc = "New File" })

-- Add this file, or the selected lines, to the prompt pane's draft (config/prompt_ref.lua).
vim.keymap.set("n", "<leader>ap", function()
  require("config.prompt_ref").add()
end, { desc = "Add File to Claude Prompt" })
vim.keymap.set("x", "<leader>ap", function()
  require("config.prompt_ref").add_selection()
end, { desc = "Add Lines to Claude Prompt" })

-- The outline in a picker rather than a loclist split (config/outline.lua).
-- <leader>o is the short way; gO stays on the picker so the runtime's split never returns.
for _, lhs in ipairs({ "<leader>o", "gO" }) do
  vim.keymap.set("n", lhs, function()
    require("config.outline").open()
  end, { desc = "Outline" })
end

-- Habit capture: the last keys, the text before and after, and a note, to the Vim
-- inbox in the vault for /vim-inbox to answer (config/habit_capture.lua).
require("config.habit_capture").setup()
vim.keymap.set("n", "<leader>hh", function()
  require("config.habit_capture").capture("<leader>hh")
end, { desc = "Capture Habit" })
vim.keymap.set("n", "<leader>hi", function()
  require("config.habit_capture").open_inbox()
end, { desc = "Vim Inbox" })

-- :ConfigReload picks up edits to lua/config/ in a running nvim (config/reload.lua).
require("config.reload")

-- Issue buffers show blockers, blocked issues, parent and sub-issues (config/issue.lua).
require("config.issue").setup()

-- gx on an issue ref (dots-issues#67, hefker/nixos-issues#155) opens the issue on
-- GitHub; anything else falls through to the built-in gx (urls, paths).
local function issue_ref_url(text)
  local repo, n = (text or ""):match("[Hh]ef[Kk]er/(%a+)%-issues#(%d+)")
  if not repo then
    repo, n = (text or ""):match("(%a+)%-issues#(%d+)")
  end
  if repo and (repo:lower() == "dots" or repo:lower() == "nixos") then
    return ("https://github.com/hefker/%s-issues/issues/%s"):format(repo:lower(), n)
  end
end

-- The runtime's own gx, captured before it is replaced below.
-- Kept in a global so a :ConfigReload doesn't capture this override as the builtin.
_G.builtin_gx = _G.builtin_gx
  or {
    n = vim.fn.maparg("gx", "n", false, true).callback,
    x = vim.fn.maparg("gx", "x", false, true).callback,
  }
local builtin_gx = _G.builtin_gx

vim.keymap.set("n", "gx", function()
  local url = issue_ref_url(vim.fn.expand("<cWORD>"))
  if url then
    return vim.ui.open(url)
  end
  builtin_gx.n()
end, { desc = "Open link or issue ref" })

vim.keymap.set("x", "gx", function()
  local sel = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() }), "\n")
  local url = issue_ref_url(sel)
  if url then
    vim.ui.open(url)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  else
    builtin_gx.x()
  end
end, { desc = "Open link or issue ref" })
