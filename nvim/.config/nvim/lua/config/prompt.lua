-- Prompt pane: a scratch buffer for writing to the Claude agent in the same herdr tab,
-- so the agent stays readable and scrollable while composing. Opened by the
-- `prefix+a` command in herdr/.config/herdr/config.toml, through scripts/claude-prompt.
local M = {}

-- herdr prints errors as JSON on stderr; fall back to the raw text for anything else.
local function herdr_error(result)
  local ok, decoded = pcall(vim.json.decode, result.stderr)
  return ok and vim.tbl_get(decoded, "error", "message") or vim.trim(result.stderr)
end

-- Looked up on every send, not at open, so restarting Claude doesn't strand the pane.
local function find_agent()
  local listed = vim
    .system({ "herdr", "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID }, { text = true })
    :wait()
  if listed.code ~= 0 then
    return nil, herdr_error(listed)
  end
  local agents = vim.tbl_filter(function(pane)
    return pane.tab_id == vim.env.HERDR_TAB_ID and pane.agent == "claude"
  end, vim.json.decode(listed.stdout).result.panes)
  if #agents ~= 1 then
    return nil, ("Expected one Claude pane in this tab, found %d"):format(#agents)
  end
  return agents[1].pane_id
end

local function send()
  local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  if text == "" then
    return
  end
  local pane, err = find_agent()
  if pane then
    -- `agent prompt` rather than `pane send-text`: it pastes, so newlines don't submit
    -- early and Claude's vim mode can't run the text, and it refuses a blocked agent.
    local sent = vim.system({ "herdr", "agent", "prompt", pane, text }, { text = true }):wait()
    err = sent.code ~= 0 and herdr_error(sent) or nil
  end
  if err then
    vim.notify(err, vim.log.levels.ERROR, { title = "Claude prompt" })
    return
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end

-- Runs in the .md file scripts/claude-prompt opens, not an empty buffer: a file argument
-- is what skips the dashboard and makes LazyVim load its markdown autocmds in time.
function M.open()
  vim.fn.delete(vim.api.nvim_buf_get_name(0))
  vim.bo.buftype = "nofile"
  vim.bo.swapfile = false
  vim.keymap.set("n", "<leader>as", send, { buffer = true, desc = "Send Prompt to Claude" })
  vim.cmd.normal({ "G", bang = true })
  vim.cmd.startinsert({ bang = true })
end

return M
