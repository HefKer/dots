-- Where Obsidian puts a vault's attachments and new notes, so nvim saves pasted
-- images, finds ![[name.png]] embeds and creates notes where the app does.
local M = {}

---@param path string absolute path of a note, or a directory
---@return string? vault root, or nil when the path is in no vault
function M.vault(path)
  local start = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  local marker = vim.fs.find(".obsidian", { path = start, upward = true, type = "directory" })[1]
  return marker and vim.fs.dirname(marker)
end

---@param vault string
---@return table the vault's .obsidian/app.json, or {} when unreadable
local function app_config(vault)
  local ok, app = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(vault .. "/.obsidian/app.json"), "\n"))
  end)
  return ok and type(app) == "table" and app or {}
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
  local setting = app_config(vault).attachmentFolderPath or "/"
  if setting == "" or setting == "/" then
    return vault
  elseif setting == "." or setting:sub(1, 2) == "./" then
    return vim.fs.normalize(vim.fs.dirname(file) .. "/" .. setting:sub(3))
  end
  return vim.fs.normalize(vault .. "/" .. setting)
end

--- The folder Obsidian would create a new note in, following its "Default
--- location for new notes" setting (newFileLocation): "folder" is
--- newFileFolderPath, "current" the open note's folder, and unset the vault root.
---@param vault string
---@param current? string absolute path of the open note
---@return string absolute directory
function M.new_note_dir(vault, current)
  local app = app_config(vault)
  if app.newFileLocation == "folder" and app.newFileFolderPath then
    return vim.fs.normalize(vault .. "/" .. app.newFileFolderPath)
  elseif app.newFileLocation == "current" and current and M.vault(current) == vault then
    return vim.fs.dirname(current)
  end
  return vault
end

--- Prompt for a name and open that note in the folder Obsidian would create it
--- in, for the vault of the current file or else of the cwd. Outside a vault,
--- open an empty buffer as LazyVim's <leader>fn does.
function M.new_note()
  local current = vim.api.nvim_buf_get_name(0)
  local vault = (current ~= "" and M.vault(current)) or M.vault(vim.fn.getcwd())
  if not vault then
    return vim.cmd.enew()
  end
  local dir = M.new_note_dir(vault, current ~= "" and current or nil)
  vim.ui.input({ prompt = "New note in " .. vim.fs.basename(dir) .. "/: " }, function(name)
    name = name and vim.trim(name) or ""
    if name == "" then
      return
    end
    if not name:match("%.md$") then
      name = name .. ".md"
    end
    vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. name), "p")
    vim.cmd.edit(vim.fn.fnameescape(dir .. "/" .. name))
  end)
end

return M
