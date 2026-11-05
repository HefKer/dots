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
