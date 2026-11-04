-- Where Obsidian keeps a vault's attachments, so nvim saves pasted images and
-- finds ![[name.png]] embeds in the same place the Obsidian app does.
local M = {}

---@param file string absolute path of a note
---@return string? vault root, or nil when the file is in no vault
function M.vault(file)
  local marker = vim.fs.find(".obsidian", { path = vim.fs.dirname(file), upward = true, type = "directory" })[1]
  return marker and vim.fs.dirname(marker)
end

--- The attachment folder Obsidian would use for a note, following its
--- "Default location for new attachments" setting (attachmentFolderPath):
--- "/" or unset is the vault root, "./" the note's folder, "./sub" a subfolder
--- of it, and anything else a path from the vault root.
---@param file string absolute path of a note
---@return string? absolute directory, or nil when the file is in no vault
function M.attachment_dir(file)
  local vault = M.vault(file)
  if not vault then
    return nil
  end
  local ok, app = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(vault .. "/.obsidian/app.json"), "\n"))
  end)
  local setting = ok and type(app) == "table" and app.attachmentFolderPath or "/"
  if setting == "" or setting == "/" then
    return vault
  elseif setting == "." or setting:sub(1, 2) == "./" then
    return vim.fs.normalize(vim.fs.dirname(file) .. "/" .. setting:sub(3))
  end
  return vim.fs.normalize(vault .. "/" .. setting)
end

return M
