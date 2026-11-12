-- <leader>ap in any nvim inside herdr: adds `@file` (or `@file#L10-20` for a visual
-- selection) to the prompt pane's draft for the Claude in this tab, opening the pane
-- through scripts/claude-prompt when there isn't one, and focuses it to keep writing.
-- The reference is relative to Claude's directory when the file is under it.
local prompt = require("config.prompt")

local M = {}

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Claude prompt" })
end

local function prompt_pane()
  local listed = vim
    .system({ "herdr", "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID }, { text = true })
    :wait()
  if listed.code ~= 0 then
    return nil
  end
  for _, pane in ipairs(vim.json.decode(listed.stdout).result.panes) do
    if pane.tab_id == vim.env.HERDR_TAB_ID and pane.label == "prompt" then
      return pane.pane_id
    end
  end
end

---@param agent table Claude's pane, from config.prompt.find_agent
---@param from? integer first line of a selection
---@param to? integer
local function reference(agent, from, to)
  local path = vim.api.nvim_buf_get_name(0)
  local cwd = prompt.workdir(agent)
  if cwd and vim.startswith(path, cwd .. "/") then
    path = path:sub(#cwd + 2)
  end
  local lines = ""
  if from then
    lines = from == to and ("#L%d"):format(from) or ("#L%d-%d"):format(from, to)
  end
  return "@" .. path .. lines
end

-- The prompt pane's nvim only listens once it has opened, so a pane just opened by
-- scripts/claude-prompt is waited for.
local function connect(pane_id)
  local sock = prompt.socket(pane_id)
  for _ = 1, 50 do
    local ok, chan = pcall(vim.fn.sockconnect, "pipe", sock, { rpc = true })
    if ok and chan > 0 then
      return chan
    end
    vim.wait(100)
  end
end

function M.add(from, to)
  if vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) == "" then
    return notify_error("Not a file")
  end
  if not vim.env.HERDR_TAB_ID then
    return notify_error("Not inside herdr")
  end
  local agent, err = prompt.find_agent()
  if not agent then
    return notify_error(err)
  end
  local ref = reference(agent, from, to)

  local pane_id = prompt_pane()
  if not pane_id then
    -- As herdr's prefix+a would, over this tab's Claude.
    vim
      .system({ vim.fn.expand("~/dots/scripts/claude-prompt") }, {
        env = { HERDR_ACTIVE_PANE_ID = agent.pane_id },
      })
      :wait()
    pane_id = prompt_pane()
  end
  local chan = pane_id and connect(pane_id)
  if not chan then
    return notify_error("Couldn't reach the prompt pane")
  end
  vim.rpcrequest(chan, "nvim_exec_lua", "require('config.prompt').add_ref(...)", { ref })
  vim.fn.chanclose(chan)
  vim.system({ "herdr", "pane", "zoom", pane_id, "--on" }):wait()
end

function M.add_selection()
  local from, to = vim.fn.line("v"), vim.fn.line(".")
  vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
  M.add(math.min(from, to), math.max(from, to))
end

return M
