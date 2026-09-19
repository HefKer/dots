-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- smart-splits: move/resize across nvim splits and wezterm panes alike.
-- Mods match wezterm/.config/wezterm/keys.lua (split_nav): CTRL to move, CTRL+ALT to resize.
local splits = function(fn)
  return function()
    require("smart-splits")[fn]()
  end
end

vim.keymap.set("n", "<C-h>", splits("move_cursor_left"), { desc = "Go to Left Window/Pane" })
vim.keymap.set("n", "<C-j>", splits("move_cursor_down"), { desc = "Go to Lower Window/Pane" })
vim.keymap.set("n", "<C-k>", splits("move_cursor_up"), { desc = "Go to Upper Window/Pane" })
vim.keymap.set("n", "<C-l>", splits("move_cursor_right"), { desc = "Go to Right Window/Pane" })

vim.keymap.set("n", "<C-A-h>", splits("resize_left"), { desc = "Resize Window Left" })
vim.keymap.set("n", "<C-A-j>", splits("resize_down"), { desc = "Resize Window Down" })
vim.keymap.set("n", "<C-A-k>", splits("resize_up"), { desc = "Resize Window Up" })
vim.keymap.set("n", "<C-A-l>", splits("resize_right"), { desc = "Resize Window Right" })
