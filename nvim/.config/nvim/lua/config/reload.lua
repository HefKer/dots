-- :ConfigReload, and scripts/nvim-reload, which runs it in every nvim: picks up edits
-- to lua/config/ without a restart. Every config.* module is unloaded, so the next
-- require reads the new file; options, keymaps and autocmds run again; and an open
-- prompt pane (config/prompt.lua) is torn down by its old copy and taken over by the
-- new one, keeping its text. Plugin specs (lua/plugins/) and blink's prompt source,
-- which blink keeps the instance of, still need a restart.
local M = {}

-- Loaded by lazy.nvim's bootstrap, and this module, which is running.
local keep = { ["config.lazy"] = true, ["config.reload"] = true }

---@return string what happened, one line
function M.run()
  local errors = {}
  local function try(what, fn)
    local ok, err = pcall(fn)
    if not ok then
      table.insert(errors, what .. ": " .. tostring(err))
    end
    return ok
  end

  local pane
  local old = package.loaded["config.prompt"]
  if old and old.teardown then
    try("prompt teardown", function()
      pane = old.teardown()
    end)
  end
  local tables = package.loaded["config.markdown_tables"] ~= nil

  for name in pairs(package.loaded) do
    if name:match("^config%.") and not keep[name] then
      package.loaded[name] = nil
    end
  end

  for _, name in ipairs({ "options", "keymaps", "autocmds" }) do
    try(name, function()
      require("config." .. name)
    end)
  end
  -- Its setup clears its group, which held the autocmds of buffers already open.
  if tables then
    try("markdown_tables", function()
      require("config.markdown_tables").setup()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
          vim.api.nvim_exec_autocmds("FileType", { group = "markdown_tables", buffer = buf })
        end
      end
    end)
  end
  if pane then
    try("prompt pane", function()
      require("config.prompt").open({ adopt = pane })
    end)
  end

  local msg = "Config reloaded" .. (pane and ", prompt pane kept" or "")
  if #errors > 0 then
    msg = msg .. "; failed: " .. table.concat(errors, "; ")
    vim.notify(msg, vim.log.levels.ERROR, { title = "Config reload" })
  else
    vim.notify(msg, vim.log.levels.INFO, { title = "Config reload" })
  end
  return msg
end

vim.api.nvim_create_user_command("ConfigReload", function()
  M.run()
end, { desc = "Reload lua/config/ without restarting" })

return M
