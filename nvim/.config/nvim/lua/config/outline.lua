-- gO: the buffer's outline in a snacks picker instead of a location-list split.
-- Buffers whose runtime ftplugin builds a table of contents (help, man, markdown,
-- checkhealth) get their headings, LSP or not; other buffers get LSP symbols, as
-- <leader>ss shows them.
local M = {}

-- The runtime ftplugins' gO bodies, each of which fills the loclist and lopens it.
local toc = {
  help = function()
    require("vim.treesitter._headings").show_toc()
  end,
  markdown = function()
    require("vim.treesitter._headings").show_toc()
  end,
  checkhealth = function()
    require("vim.treesitter._headings").show_toc(6)
  end,
  man = function()
    require("man").show_toc()
  end,
}
M.filetypes = vim.tbl_keys(toc)

local function headings(fill)
  local src = vim.api.nvim_get_current_win()
  fill()
  local list = vim.fn.getloclist(src, { items = 1 }).items
  -- Close the split the runtime opened, back in the source window.
  if vim.api.nvim_win_is_valid(src) then
    vim.api.nvim_set_current_win(src)
  end
  vim.cmd.lclose()

  local items = {}
  for i, it in ipairs(list) do
    if it.valid == 1 then
      local label = it.text:gsub("\194\160", " ")
      items[#items + 1] = { idx = i, text = label, buf = it.bufnr, pos = { it.lnum, 0 } }
    end
  end
  if #items == 0 then
    return vim.notify("No headings", vim.log.levels.INFO)
  end
  Snacks.picker({
    title = "Outline",
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = "file",
    sort = { fields = { "score:desc", "idx" } },
  })
end

function M.open()
  local fill = toc[vim.bo.filetype]
  if fill then
    return headings(fill)
  end
  Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter })
end

-- Runtime ftplugins set a buffer-local gO, which beats a global one; drop it.
function M.unmap(buf)
  pcall(vim.keymap.del, "n", "gO", { buffer = buf })
end

return M
