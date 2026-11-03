-- Rename a file by its name alone: the prompt holds the name without its
-- directory or extension, and both stay as they were. To move a file or change
-- its extension, use the explorer's `m`.
local M = {}

---@param file string
---@param on_rename? fun(to: string, from: string, ok: boolean)
function M.rename(file, on_rename)
  file = vim.fn.fnamemodify(file, ":p"):gsub("/$", "")
  local dir, tail = vim.fs.dirname(file), vim.fs.basename(file)
  -- ".gitignore" has no extension; "trig. graph.md" has only ".md"
  local ext = vim.fn.isdirectory(file) == 0 and tail:match("^.+(%.[^.]+)$") or ""
  local name = tail:sub(1, #tail - #ext)

  vim.ui.input({ prompt = "Rename: ", default = name }, function(value)
    if not value or value == "" or value == name then
      return
    end
    local to = dir .. "/" .. value .. ext
    -- rename() replaces an existing file without asking
    if vim.uv.fs_stat(to) then
      Snacks.notify.error("Already exists: `" .. vim.fn.fnamemodify(to, ":~:.") .. "`")
      return
    end
    Snacks.rename.rename_file({ from = file, to = to, on_rename = on_rename })
  end)
end

return M
