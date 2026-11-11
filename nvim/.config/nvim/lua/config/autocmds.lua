-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- gO's runtime buffer-local maps would shadow the picker one in keymaps.lua.
local outline = require("config.outline")
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("outline_picker", { clear = true }),
  pattern = outline.filetypes,
  -- Scheduled, so it runs after the ftplugin however the autocmds are ordered.
  callback = function(ev)
    vim.schedule(function()
      outline.unmap(ev.buf)
    end)
  end,
})
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.tbl_contains(outline.filetypes, vim.bo[buf].filetype) then
    outline.unmap(buf)
  end
end
