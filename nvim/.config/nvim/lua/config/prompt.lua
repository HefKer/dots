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
  return agents[1]
end

-- From the transcript, not the screen: that's the exact markdown, unwrapped and complete.
local function last_reply(session)
  local path = vim.fn.glob("~/.claude/projects/*/" .. session .. ".jsonl", false, true)[1]
  local lines = path and vim.fn.readfile(path) or {}
  for i = #lines, 1, -1 do
    local ok, entry = pcall(vim.json.decode, lines[i])
    if ok and entry.type == "assistant" and entry.isSidechain ~= true then
      local text = vim.tbl_filter(function(block)
        return block.type == "text"
      end, entry.message.content)
      if #text > 0 then
        return table.concat(
          vim.tbl_map(function(block)
            return block.text
          end, text),
          "\n"
        )
      end
    end
  end
end

local function send()
  local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  if text == "" then
    return
  end
  local agent, err = find_agent()
  if agent then
    -- `agent prompt` rather than `pane send-text`: it pastes, so newlines don't submit
    -- early and Claude's vim mode can't run the text, and it refuses a blocked agent.
    local sent = vim.system({ "herdr", "agent", "prompt", agent.pane_id, text }, { text = true }):wait()
    err = sent.code ~= 0 and herdr_error(sent) or nil
  end
  if err then
    vim.notify(err, vim.log.levels.ERROR, { title = "Claude prompt" })
    return
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
end

-- Blockquoted, for replying between its lines and deleting what doesn't need an answer.
local function quote()
  local agent, err = find_agent()
  local session = agent and vim.tbl_get(agent, "agent_session", "value")
  local reply = session and last_reply(session)
  if not reply then
    vim.notify(err or "No reply to quote yet", vim.log.levels.ERROR, { title = "Claude prompt" })
    return
  end
  local lines = vim.tbl_map(function(line)
    return vim.trim("> " .. line)
  end, vim.split(reply, "\n"))
  table.insert(lines, "")
  vim.api.nvim_put(lines, "l", false, false)
end

-- Runs in the .md file scripts/claude-prompt opens, not an empty buffer: a file argument
-- is what skips the dashboard and makes LazyVim load its markdown autocmds in time.
function M.open()
  vim.fn.delete(vim.api.nvim_buf_get_name(0))
  vim.bo.buftype = "nofile"
  vim.bo.swapfile = false
  vim.keymap.set("n", "<leader>as", send, { buffer = true, desc = "Send Prompt to Claude" })
  vim.keymap.set("n", "<leader>aq", quote, { buffer = true, desc = "Quote Claude's Last Reply" })
  vim.cmd.normal({ "G", bang = true })
  vim.cmd.startinsert({ bang = true })
end

return M
