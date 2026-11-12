-- Prompt pane: a scratch buffer for writing to the Claude agent in the same herdr tab,
-- with Claude's last reply rendered in a read-only window above it, so you can read,
-- scroll and quote the reply while composing. Opened by the `prefix+a` command in
-- herdr/.config/herdr/config.toml, through scripts/claude-prompt.
local M = {}

local tables = require("config.prompt_table")
local queue = require("config.prompt_queue")
local handoff = require("config.prompt_handoff")
local pending = require("config.prompt_pending")

local ns = vim.api.nvim_create_namespace("claude_prompt_quote")
local ns_table = vim.api.nvim_create_namespace("claude_prompt_table")

-- One prompt pane per nvim, so its state is module-wide.
local state = {
  prompt = { buf = nil, win = nil },
  viewer = { buf = nil, win = nil },
  shown = { lines = {}, source = {} }, -- the reply's markdown, and viewer rows drawn from its tables
  path = nil, -- transcript being read
  offset = 0, -- bytes of it already parsed
  partial = "", -- a line still being written when last read
  replies = {}, -- finished replies, oldest first; those with no prompt of yours between are one
  prompted = true, -- whether you've written to Claude since its last reply
  session = nil, -- Claude's session id, last seen
  draft = nil, -- file the prompt is saved to
  index = 0, -- the one shown; 0 when there are none
  view = "reply", -- or "tasks", the task list shown in its place, or "pending", the call Claude is blocked on
  tasks = {}, -- Claude's task list: { id?, subject, status }
  activity = nil, -- the tool call Claude made last, while a turn runs
  calls = {}, -- tool calls made this turn with no result yet, oldest first (config.prompt_pending)
  answered = {}, -- ids of calls answered from here, before their result is written
  shown_call = nil, -- the call the viewer shows, keyed by call_key
  screen = nil, -- Claude's screen text, read while it's blocked
  answered_screen = nil, -- a dialog known only from the screen, answered from here
  watcher = nil,
  timer = nil,
  unseen = false, -- a reply arrived while a file covered the viewer
  queue = nil, -- the command queue being sent: { n, total, label }
  stop_queue = nil, -- stops it, putting back what isn't sent yet: fun(why: string)
  interrupted = false, -- shown in the viewer's bar for a moment after an interrupt
  mode = nil, -- Claude's permission mode, from whichever was read last: transcript or screen
  cwd = nil, -- Claude's working directory, and its git branch
  branch = nil,
}

-- The viewer window's look while it shows the reply; a file shown there gets the
-- global values back. Set with vim.wo[win][0], like :setlocal, so other windows keep them.
local viewer_opts =
  { number = true, relativenumber = true, signcolumn = "no", spell = false, wrap = true, linebreak = true }

-- herdr prints errors as JSON on stderr; fall back to the raw text for anything else.
local function herdr_error(result)
  local ok, decoded = pcall(vim.json.decode, result.stderr)
  return ok and vim.tbl_get(decoded, "error", "message") or vim.trim(result.stderr)
end

-- The pane's session, from Claude's own record (<config dir>/sessions/<pid>.json) of
-- the process running in it. herdr's agent_session can go stale: a fresh Claude
-- started in a pane whose last one had none (csend's fallback, prefix+u on an empty
-- session) is never picked up by herdr, which keeps the old id, so the reply never
-- updates. herdr's id is the fallback, for a Claude without the record.
---@param agent table a pane from `herdr pane list`
local function claude_session(agent)
  local found, started = nil, -1
  for _, file in ipairs(vim.fn.glob("~/.claude*/sessions/*.json", false, true)) do
    local fh = io.open("/proc/" .. vim.fn.fnamemodify(file, ":t:r") .. "/environ", "rb")
    local env = fh and fh:read("*a")
    if fh then
      fh:close()
    end
    if env and ("\0" .. env):find("\0HERDR_PANE_ID=" .. agent.pane_id .. "\0", 1, true) then
      local ok, record = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
      end)
      if ok and type(record) == "table" and record.sessionId and (record.startedAt or 0) > started then
        found, started = record.sessionId, record.startedAt or 0
      end
    end
  end
  return found or vim.tbl_get(agent, "agent_session", "value")
end

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Claude prompt" })
end

---@param listed vim.SystemCompleted output of `herdr pane list`
local function pick_agent(listed)
  if listed.code ~= 0 then
    return nil, herdr_error(listed)
  end
  local agents = vim.tbl_filter(function(pane)
    return pane.tab_id == vim.env.HERDR_TAB_ID and pane.agent == "claude"
  end, vim.json.decode(listed.stdout).result.panes)
  if #agents ~= 1 then
    return nil, ("Expected one Claude pane in this tab, found %d"):format(#agents)
  end
  agents[1].session = claude_session(agents[1])
  return agents[1]
end

local function list_panes()
  return { "herdr", "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID }
end

-- Looked up on every send, not at open, so restarting Claude doesn't strand the pane.
function M.find_agent()
  return pick_agent(vim.system(list_panes(), { text = true }):wait())
end

-- The directory Claude's @ paths are relative to, by one rule for the bar, @ completion
-- and config.prompt_ref: its foreground process's, else its pane's.
---@param agent? table a pane from `herdr pane list`
---@return string?
function M.workdir(agent)
  local cwd = agent and agent.foreground_cwd
  if type(cwd) ~= "string" then
    cwd = agent and agent.cwd
  end
  return type(cwd) == "string" and cwd or nil
end

---@return string? path of the agent's session transcript
---@return string? err
local function session_path(agent, err)
  local session = agent and agent.session
  if not session then
    return nil, err or "Claude has no session yet"
  end
  -- ~/.claude* covers both accounts' config dirs, ~/.claude and ~/.claude-hulio.
  local path = vim.fn.glob("~/.claude*/projects/*/" .. session .. ".jsonl", false, true)[1]
  return path, not path and "No transcript for this session yet" or nil
end

function M.transcript()
  return session_path(M.find_agent())
end

-- The same, without blocking: for the background check, so typing never stalls on herdr.
---@param cb fun(path?: string, err?: string, agent?: table)
function M.transcript_async(cb)
  vim.system(
    list_panes(),
    { text = true },
    vim.schedule_wrap(function(listed)
      local agent, err = pick_agent(listed)
      local path, path_err = session_path(agent, err)
      cb(path, path_err, agent)
    end)
  )
end

------------------------------------------------------------------------------
-- Replies, read from the transcript rather than the screen: that's the exact
-- markdown, unwrapped and complete. Only a turn's final answer counts (the text
-- Claude ends the turn with, stop_reason end_turn), so the narration it writes
-- between tool calls never replaces the reply you're reading.

-- What a tool call is doing, for the bar while Claude works: "Edit prompt.lua",
-- "Bash Run the tests", an MCP tool by its own name.
local function describe(block)
  local input = block.input or {}
  local name = block.name:gsub("^mcp__.-__", "")
  local detail = input.file_path and vim.fs.basename(input.file_path)
    or input.description
    or input.command
    or input.pattern
    or input.query
    or input.url
    or input.skill
  if type(detail) ~= "string" then
    return name
  end
  detail = vim.trim(detail:match("^[^\n]*"))
  if vim.fn.strchars(detail) > 40 then
    detail = vim.fn.strcharpart(detail, 0, 39) .. "…"
  end
  return name .. " " .. detail
end

-- Claude's task list, rebuilt from its task tools: TaskCreate's result carries the new
-- task's id, TaskUpdate's the status change; an older Claude's TodoWrite sends it whole.
local function track(entry)
  if entry.type == "assistant" then
    for _, block in ipairs(entry.message.content or {}) do
      if block.type == "tool_use" then
        state.activity = describe(block)
        table.insert(state.calls, { id = block.id, name = block.name, input = block.input })
        if block.name == "TodoWrite" and block.input and block.input.todos then
          state.tasks = vim.tbl_map(function(todo)
            return { subject = todo.content, status = todo.status }
          end, block.input.todos)
          state.tasks_changed = true
        end
      end
    end
  elseif type(entry.toolUseResult) == "table" then
    local result = entry.toolUseResult
    if type(result.task) == "table" and result.task.id then
      table.insert(state.tasks, { id = result.task.id, subject = result.task.subject, status = "pending" })
      state.tasks_changed = true
    elseif result.taskId and type(result.statusChange) == "table" then
      for i, task in ipairs(state.tasks) do
        if task.id == result.taskId then
          if result.statusChange.to == "deleted" then
            table.remove(state.tasks, i)
          else
            task.status = result.statusChange.to
          end
          state.tasks_changed = true
          break
        end
      end
    end
  end
end

-- Whether a user entry is something you wrote: a prompt or a /command, not a tool
-- result, an injected reminder, a background task's notification or `!` output.
function M.from_you(entry)
  if entry.type ~= "user" or entry.isMeta or entry.isSidechain or entry.toolUseResult ~= nil then
    return false
  end
  local content = entry.message and entry.message.content
  if type(content) == "table" then
    for _, block in ipairs(content) do
      if block.type == "tool_result" then
        return false
      end
    end
    return true
  end
  return type(content) == "string"
    and not content:find("^<task%-notification>")
    and not content:find("^<bash%-std")
    and not content:find("^<local%-command")
end

-- Parses whatever was appended since the last read, so a long session isn't
-- re-read on every write. Replies Claude ends several turns with, with no prompt of
-- yours between (a background task finishing, say), join the one before them, so
-- none is hidden behind the newest. Returns whether a reply arrived, and whether
-- it was joined to the last one rather than starting a new one.
local function read_new()
  local fh = state.path and io.open(state.path, "rb")
  if not fh then
    return false
  end
  fh:seek("set", state.offset)
  local chunk = fh:read("*a") or ""
  fh:close()
  state.offset = state.offset + #chunk
  local text = state.partial .. chunk
  local last_nl = text:find("\n[^\n]*$")
  state.partial = last_nl and text:sub(last_nl + 1) or text
  text = last_nl and text:sub(1, last_nl) or ""

  local before, last_id, joined = #state.replies, state.last_id, false
  -- A message's content blocks arrive as separate entries; join them.
  local function add(body, id)
    local last = state.replies[#state.replies]
    if id and id == last_id then
      state.replies[#state.replies] = last .. "\n" .. body
      joined = joined or #state.replies == before
    elseif last and not state.prompted then
      state.replies[#state.replies] = last .. "\n\n---\n\n" .. body
      joined = joined or #state.replies == before
    else
      table.insert(state.replies, body)
    end
    last_id = id
    state.prompted = false
  end
  for line in text:gmatch("[^\n]+") do
    if line:find('"type":"user"', 1, true) and not line:find('"tool_use_id"', 1, true) then
      local ok, entry = pcall(vim.json.decode, line)
      if ok and type(entry) == "table" and M.from_you(entry) then
        state.prompted = true
        state.calls = {} -- a prompt, or an interrupt: whatever was asked is over
      end
    end
    -- Written as each turn starts, not when the mode changes: the screen is read for that.
    if line:find('"type":"permission-mode"', 1, true) then
      local ok, entry = pcall(vim.json.decode, line)
      if
        ok
        and type(entry) == "table"
        and entry.type == "permission-mode"
        and type(entry.permissionMode) == "string"
      then
        state.mode = entry.permissionMode
      end
    end
    -- A tool result answers its call. Found without decoding: these lines hold tool output.
    if line:find('"type":"tool_result"', 1, true) then
      for id in line:gmatch('"tool_use_id":"([^"]+)"') do
        state.calls = vim.tbl_filter(function(call)
          return call.id ~= id
        end, state.calls)
      end
    end
    if line:find('"type":"tool_use"', 1, true) or line:find('"toolUseResult":{', 1, true) then
      local ok, entry = pcall(vim.json.decode, line)
      if ok and type(entry) == "table" and entry.message and entry.isSidechain ~= true then
        track(entry)
      end
    end
    -- Cheap filter first: Claude Code writes compact JSON, and most lines are tool output.
    if line:find('"stop_reason":"end_turn"', 1, true) then
      local ok, entry = pcall(vim.json.decode, line)
      if ok and entry.type == "assistant" and entry.isSidechain ~= true then
        local texts = {}
        for _, block in ipairs(entry.message.content or {}) do
          if block.type == "text" then
            table.insert(texts, block.text)
          end
        end
        if #texts > 0 then
          add(table.concat(texts, "\n"), entry.message.id)
          state.activity = nil
          state.calls = {}
        end
      end
    end
    -- The recap Claude writes when you come back after being away (awaySummaryEnabled),
    -- shown as it is under Claude's input box: with the last reply, unless you've
    -- prompted since.
    if line:find('"subtype":"away_summary"', 1, true) then
      local ok, entry = pcall(vim.json.decode, line)
      if ok and type(entry) == "table" and entry.type == "system" and type(entry.content) == "string" then
        add("_Recap:_ " .. entry.content:gsub("%s*%(disable recaps in /config%)$", ""))
      end
    end
  end
  state.last_id = last_id
  return #state.replies > before, joined
end

------------------------------------------------------------------------------
-- Viewer

-- Whether the reply is on screen: a file opened in the pane can cover it.
local function viewer_valid()
  local win = state.viewer.win
  return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == state.viewer.buf
end

-- What Claude's own statusline would show, hidden under the zoomed pane: its state
-- from herdr, and context from the render ~/.claude/statusline.sh shares. Usage
-- limits are left to herdr's tab bar.
local status_hl =
  { working = "DiagnosticWarn", blocked = "DiagnosticError", idle = "DiagnosticOk", done = "DiagnosticOk" }

local mode_hl = { plan = "DiagnosticInfo", bypassPermissions = "DiagnosticError" }

local function pct_hl(pct)
  return pct >= 80 and "DiagnosticError" or pct >= 50 and "DiagnosticWarn" or "Comment"
end

local function status_line()
  local parts = {}
  -- The statusline's account badge is hidden under this pane too; hulio is someone else's quota.
  if (state.statusline or {}).account == "hulio" then
    table.insert(parts, "%#DiagnosticHint#hulio")
  end
  -- So is the model, and its effort level.
  local model = vim.tbl_get(state.statusline or {}, "model", "display_name")
  if type(model) == "string" then
    local effort = vim.tbl_get(state.statusline, "effort", "level")
    local text = "%#Special#" .. model:gsub("%%", "%%%%")
    if type(effort) == "string" then
      text = text .. "%#Comment# " .. effort:gsub("%%", "%%%%")
    end
    table.insert(parts, text)
  end
  -- So is the permission mode, when it isn't the default.
  if state.mode and state.mode ~= "default" then
    table.insert(parts, ("%%#%s#%s"):format(mode_hl[state.mode] or "DiagnosticWarn", (state.mode:gsub("%%", "%%%%"))))
  end
  if state.status then
    local activity = state.status == "working" and state.activity
    table.insert(
      parts,
      ("%%#%s#%s"):format(status_hl[state.status] or "Comment", state.status)
        .. (activity and ("%#Comment# " .. activity:gsub("%%", "%%%%")) or "")
    )
  end
  local info = state.statusline or {}
  local window = info.context_window or {}
  if window.used_percentage and window.total_input_tokens then
    local tokens = window.total_input_tokens + (window.total_output_tokens or 0)
    table.insert(parts, ("%%#%s#%.1fk ctx"):format(pct_hl(window.used_percentage), tokens / 1000))
  end
  return #parts > 0 and ("%#Comment# · " .. table.concat(parts, "%#Comment# · ")) or ""
end

-- Re-read on every poll; a missing file (a Claude without the shared statusline)
-- just leaves those parts out.
local function read_statusline(agent)
  local session = agent and agent.session
  local path = session and ("%s/claude-statusline/%s.json"):format(vim.env.XDG_RUNTIME_DIR or "/tmp", session)
  local ok, info = pcall(function()
    -- luanil: a fresh session's nulls (used_percentage) become nil, not truthy vim.NIL.
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"), { luanil = { object = true, array = true } })
  end)
  state.status = agent and agent.agent_status
  -- Kept through a failed lookup, so a herdr hiccup doesn't move the draft.
  state.session = session or state.session
  state.statusline = ok and info or nil
end

-- Each bar's binds, most-used first: as many as fit on its one line are shown. Keys
-- are under <leader>a, written after that prefix once, unless marked plain.
local viewer_hints = {
  { "<CR>", "quote", plain = true },
  { "s", "send" },
  { "i", "interrupt" },
  { "[r ]r", "replies", plain = true },
  { "k", "tasks" },
  { "c", "pane" },
  { "m", "mode" },
}
local pending_hints = {
  { "y", "yes" },
  { "Y", "always" },
  { "n", "no" },
  { "1-9", "option" },
  { "c", "pane" },
  { "i", "interrupt" },
}
local prompt_hints = {
  { "s", "send" },
  { "<M-c>", "interrupt", plain = true },
  { "q", "quote" },
  { "[r ]r", "replies", plain = true },
  { "h", "history" },
  { "d", "drafts" },
  { "t", "template" },
  { "Q", "unquote" },
  { "c", "pane" },
  { "m", "mode" },
  { "l", "stash" },
  { "H", "sessions" },
  { "k", "tasks" },
}

local function render_hints(hints)
  local plain, leader = {}, {}
  for _, hint in ipairs(hints) do
    table.insert(hint.plain and plain or leader, hint[1] .. " " .. hint[2])
  end
  if #leader > 0 then
    table.insert(plain, "<leader>a " .. table.concat(leader, " · "))
  end
  return table.concat(plain, " · ")
end

---@param win integer
---@param bar string the bar's left side, as a statusline string
---@param hints table[] { key, what, plain? }, most-used first
local function fit_hints(win, bar, hints)
  local room = vim.api.nvim_win_get_width(win)
    - vim.api.nvim_eval_statusline(bar, { winid = win, use_winbar = true }).width
    - 3
  local shown = {}
  for _, hint in ipairs(hints) do
    local try = vim.list_extend(vim.list_slice(shown), { hint })
    if vim.fn.strdisplaywidth(render_hints(try)) > room then
      break
    end
    shown = try
  end
  return "%=%#Comment#" .. render_hints(shown):gsub("%%", "%%%%") .. " "
end

local function set_winbars()
  if viewer_valid() then
    local done = #vim.tbl_filter(function(task)
      return task.status == "completed"
    end, state.tasks)
    local tasks = #state.tasks > 0 and ("tasks %d/%d"):format(done, #state.tasks)
    local title = state.view == "pending" and "Claude · %#DiagnosticError#waiting on you%#WinBar#"
      or state.view == "tasks" and ("Claude · " .. (tasks or "no tasks"))
      or state.index > 0 and ("Claude · reply %d/%d"):format(state.index, #state.replies)
      or "Claude · no reply yet"
    if state.view ~= "tasks" and tasks then
      title = title .. " · " .. tasks
    end
    if state.interrupted then
      title = title .. "%#DiagnosticWarn# · interrupted%#WinBar#"
    end
    if state.queue then
      title = title
        .. ("%%#DiagnosticWarn# · %s %d/%d%%#WinBar#"):format(
          (state.queue.label:gsub("%%", "%%%%")),
          state.queue.n,
          state.queue.total
        )
    end
    local bar = "%#WinBar# 󰚩 " .. title .. status_line()
    vim.wo[state.viewer.win][0].winbar = bar
      .. fit_hints(state.viewer.win, bar, state.view == "pending" and pending_hints or viewer_hints)
  end
  if state.prompt.win and vim.api.nvim_win_is_valid(state.prompt.win) then
    local where = ""
    if state.cwd then
      local dir = vim.fn.fnamemodify(state.cwd, ":~"):gsub("%%", "%%%%")
      local branch = state.branch and ("%#Comment# on %#DiagnosticHint# " .. state.branch:gsub("%%", "%%%%")) or ""
      where = "%#Comment# · %#Directory# " .. dir .. branch
    end
    local bar = "%#WinBar# 󰏫 Prompt" .. where
    vim.wo[state.prompt.win][0].winbar = bar .. fit_hints(state.prompt.win, bar, prompt_hints)
  end
end

-- Where Claude is working, for the prompt's bar: its pane's directory, and the git
-- branch there, looked up again only when the directory changes.
local function locate(agent)
  local cwd = M.workdir(agent)
  if not cwd or cwd == state.cwd then
    return
  end
  state.cwd, state.branch = cwd, nil
  set_winbars()
  vim.system(
    { "git", "-C", cwd, "branch", "--show-current" },
    { text = true },
    vim.schedule_wrap(function(out)
      if state.cwd == cwd and out.code == 0 and vim.trim(out.stdout) ~= "" then
        state.branch = vim.trim(out.stdout)
        set_winbars()
      end
    end)
  )
end

-- Fills the viewer with markdown, its tables drawn to fit the window (config.prompt_table).
local function draw(lines)
  local buf = state.viewer.buf
  local width = 80
  if viewer_valid() then
    local info = vim.fn.getwininfo(state.viewer.win)[1]
    width = info.width - info.textoff
  end
  -- one column short, so a full-width box row doesn't wrap
  local drawn = tables.render(lines, width - 1)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, drawn.lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns_table, 0, -1)
  for _, m in ipairs(drawn.marks) do
    vim.api.nvim_buf_set_extmark(buf, ns_table, m[1], m[2], { end_col = m[3], hl_group = m[4], priority = m[5] })
  end
  state.shown = { lines = lines, source = drawn.source }
end

-- Redraws the tables for a resized viewer, keeping the view near where it was.
local function redraw()
  local buf = state.viewer.buf
  if viewer_valid() and buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_win_call(state.viewer.win, function()
      local view = vim.fn.winsaveview()
      draw(state.shown.lines)
      vim.fn.winrestview(view)
    end)
  end
end

---@param index integer
---@param message? string shown instead of a reply
local function show(index, message)
  local buf = state.viewer.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  state.index, state.view = index, "reply"
  local text = message or state.replies[index] or "_No finished reply in this session yet._"
  draw(vim.split(text, "\n"))
  if viewer_valid() then
    vim.api.nvim_win_set_cursor(state.viewer.win, { 1, 0 })
  end
  set_winbars()
end

-- The task list in the viewer, in place of the reply, as markdown checkboxes.
local function show_tasks()
  local buf = state.viewer.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  state.view = "tasks"
  local box = { completed = "[x]", in_progress = "[-]" }
  local lines = #state.tasks == 0 and { "_No tasks in this session._" }
    or vim.tbl_map(function(task)
      return ("- %s %s"):format(box[task.status] or "[ ]", task.subject or "")
    end, state.tasks)
  draw(lines)
  set_winbars()
end

------------------------------------------------------------------------------
-- Claude's screen

local function lookup_agent(cb)
  vim.system(
    list_panes(),
    { text = true },
    vim.schedule_wrap(function(listed)
      cb(pick_agent(listed))
    end)
  )
end

-- M.workdir without blocking, for completion as you type: the one the poll last saw,
-- else looked up.
---@param cb fun(cwd?: string)
function M.workdir_async(cb)
  if state.cwd then
    return cb(state.cwd)
  end
  lookup_agent(function(agent)
    cb(M.workdir(agent))
  end)
end

-- Whether Claude's input box is on screen: a `❯` line under a `─` rule. A dialog such
-- as /model's picker, or a permission prompt, takes its place.
local function input_box(screen)
  local above
  for _, line in ipairs(vim.split(screen, "\n", { plain = true })) do
    if vim.trim(line) ~= "" then
      if line:find("^❯") and above and above:find("^─") then
        return true
      end
      above = line
    end
  end
  return false
end

-- Claude's permission mode by the name its footer shows; any other is passed on as shown.
local mode_names = {
  manual = "default",
  ["accept edits"] = "acceptEdits",
  ["bypass permissions"] = "bypassPermissions",
}

-- The permission mode Claude's footer shows under its input box (`⏸ plan mode on`,
-- `⏵⏵ accept edits on`), or nil with the box covered or no mode shown. A Claude that
-- shows nothing for default mode shows `? for shortcuts` there instead.
---@param screen string Claude's screen
---@return string?
function M.screen_mode(screen)
  if not input_box(screen) then
    return nil
  end
  local lines = vim.split(screen, "\n", { plain = true })
  local footer = #lines + 1
  for i = #lines, 1, -1 do
    if lines[i]:find("^─") then
      footer = i + 1
      break
    end
  end
  for i = footer, #lines do
    local line = vim.trim(lines[i])
    local name = line:match("^[^%w%s]+%s+(%a[%a ']-) on%f[^%w]")
    if name then
      name = name:gsub(" mode$", "")
      return mode_names[name] or name
    elseif line:find("^%? for shortcuts") then
      return "default"
    end
  end
  return nil
end

-- What Claude's pane shows now. herdr's agent_status alone misses a dialog: it keeps
-- the last state behind /model's picker, so the screen is read for the input box too.
---@param cb fun(screen?: "idle"|"working"|"blocked"|"dialog", agent?: table, err?: string, text?: string)
local function read_screen(cb)
  lookup_agent(function(agent, err)
    if not agent then
      return cb(nil, nil, err)
    end
    vim.system(
      { "herdr", "pane", "read", agent.pane_id, "--source", "visible" },
      { text = true },
      vim.schedule_wrap(function(read)
        if read.code ~= 0 then
          return cb(nil, agent, herdr_error(read))
        end
        local screen = agent.agent_status == "blocked" and "blocked"
          or not input_box(read.stdout) and "dialog"
          or agent.agent_status == "working" and "working"
          or "idle"
        cb(screen, agent, nil, read.stdout)
      end)
    )
  end)
end

-- Claude's permission mode from its footer, which shows a change at once, where the
-- transcript has it only once the next turn starts. Left as it was while a dialog covers it.
---@param cb? fun(mode?: string)
local function read_mode(agent, cb)
  vim.system(
    { "herdr", "pane", "read", agent.pane_id, "--source", "visible" },
    { text = true },
    vim.schedule_wrap(function(read)
      local mode = read.code == 0 and M.screen_mode(read.stdout) or nil
      if mode and mode ~= state.mode then
        state.mode = mode
        set_winbars()
      end
      if cb then
        cb(mode)
      end
    end)
  )
end

------------------------------------------------------------------------------
-- The pending call: while Claude is blocked on a tool call, the viewer shows it in
-- place of the reply (config.prompt_pending), and <leader>ay/aY/an/a1-9 answer the
-- dialog asking about it, back to the reply once answered.

-- The call Claude's dialog asks about, with the dialog's options once its screen has
-- been read: the oldest call made this turn with no result yet that the dialog shows,
-- or, while Claude holds that back from the transcript, the dialog as the screen shows
-- it. Not one answered from here.
---@return prompt.Call? call, prompt.Option[]? options
local function pending_call()
  if state.status ~= "blocked" then
    return nil
  end
  local options = state.screen and pending.options(state.screen)
  local lines = options and pending.dialog(state.screen)
  for _, call in ipairs(state.calls) do
    if not state.answered[call.id] and (not lines or pending.asks_about(call, lines)) then
      return call, options
    end
  end
  local id = lines and "screen:" .. table.concat(lines, "\n")
  if id and id ~= state.answered_screen then
    return { id = id, screen = lines }, options
  end
end

-- Which call the viewer shows, and whether with its options: once they're read, it's redrawn.
local function call_key(call, options)
  return call.id .. (options and "#" .. #options or "")
end

local function show_pending(call, options)
  local buf = state.viewer.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  state.view, state.shown_call = "pending", call_key(call, options)
  draw(pending.render(call, options))
  if viewer_valid() then
    vim.api.nvim_win_set_cursor(state.viewer.win, { 1, 0 })
  end
  set_winbars()
end

-- Shows the pending call once Claude is blocked on it, and the reply again once not.
-- Shown once per call, so [r or <leader>ak can step away from it while it waits.
local function update_pending()
  local call, options = pending_call()
  if call and state.shown_call ~= call_key(call, options) then
    show_pending(call, options)
    if not viewer_valid() then
      vim.notify("Claude is waiting on you · <leader>ar to show", vim.log.levels.WARN, { title = "Claude prompt" })
    end
  elseif not call and state.shown_call then
    state.shown_call = nil
    if state.view == "pending" then
      show(#state.replies)
    end
  end
end

-- Claude's screen while it's blocked, read for the dialog; then the pending call shown.
---@param cb fun(screen?: "idle"|"working"|"blocked"|"dialog", agent?: table, text?: string) only once read
local function read_dialog(cb)
  if state.status ~= "blocked" then
    state.screen, state.answered_screen = nil, nil
    return update_pending()
  end
  read_screen(function(screen, agent, _, text)
    state.screen = screen == "blocked" and text or nil
    update_pending()
    cb(screen, agent, text)
  end)
end

-- Back from the task list to the pending call while there is one, else the reply.
local function toggle_tasks()
  local call, options = pending_call()
  if state.view ~= "tasks" then
    show_tasks()
  elseif call and state.shown_call then
    show_pending(call, options)
  else
    show(state.index)
  end
end

-- Whether the prompt pane answers the dialog on Claude's screen itself: one whose
-- numbered options it can read. The hand-off takes the rest.
---@param text string Claude's screen
local function answerable(text)
  return pending.options(text) ~= nil
end

-- Picks up new replies and tasks. Following the newest reply unless you've stepped
-- back to an older one; the task list stays up when one arrives, redrawn as it changes.
local function refresh()
  local following = state.index == #state.replies
  local new_reply, joined = read_new()
  if (new_reply or joined) and not viewer_valid() then
    state.unseen = true
    vim.notify("Claude replied · <leader>ar to show", vim.log.levels.INFO, { title = "Claude prompt" })
  end
  if state.view == "pending" then
    if following then
      state.index = #state.replies
    end
    set_winbars()
  elseif state.view == "tasks" then
    if following then
      state.index = #state.replies
    end
    if state.tasks_changed then
      show_tasks()
    else
      set_winbars()
    end
  elseif new_reply and following then
    show(#state.replies)
  elseif joined and following and viewer_valid() then
    -- More of the reply you're reading: keep your place in it.
    vim.api.nvim_win_call(state.viewer.win, function()
      local view = vim.fn.winsaveview()
      draw(vim.split(state.replies[state.index], "\n"))
      vim.fn.winrestview(view)
    end)
    set_winbars()
    vim.notify("Claude added to its reply", vim.log.levels.INFO, { title = "Claude prompt" })
  else
    set_winbars()
  end
  state.tasks_changed = false
  update_pending()
end

-- Claude restarted or /clear'd: start over on the new transcript.
local function attach_to(path, err)
  if path == state.path then
    return refresh()
  end
  if state.watcher then
    state.watcher:stop()
  end
  state.path, state.offset, state.partial, state.replies, state.last_id = path, 0, "", {}, nil
  state.prompted = true
  state.tasks, state.activity, state.calls, state.answered = {}, nil, {}, {}
  if not path then
    return show(0, "_" .. err .. "._")
  end
  read_new()
  show(#state.replies)

  -- libuv often reports only the first of several edits, so re-arm after each one.
  state.timer = state.timer or vim.uv.new_timer()
  state.watcher = state.watcher or vim.uv.new_fs_event()
  local function arm()
    state.watcher:start(state.path, {}, function()
      state.watcher:stop()
      state.timer:start(
        150,
        0,
        vim.schedule_wrap(function()
          refresh()
          arm()
        end)
      )
    end)
  end
  arm()
end

local function attach()
  attach_to(M.transcript())
end

-- Past the newest reply is the pending call, while one waits.
local function step(delta)
  local call = state.shown_call and pending_call()
  local target = state.view == "pending" and delta < 0 and state.index or state.index + delta
  if state.view ~= "pending" and target == #state.replies + 1 and call then
    show_pending(call)
  elseif target >= 1 and target <= #state.replies then
    show(target)
  end
end

-- Scrolls the viewer from the prompt window, in normal or insert mode alike.
local function scroll(keys)
  return function()
    if viewer_valid() then
      vim.api.nvim_win_call(state.viewer.win, function()
        vim.cmd.normal({ vim.keycode(keys), bang = true })
      end)
    end
  end
end

------------------------------------------------------------------------------
-- Quoting

local function quote_lines(lines)
  while #lines > 0 and vim.trim(lines[#lines]) == "" do
    table.remove(lines)
  end
  return vim.tbl_map(function(line)
    return vim.trim("> " .. line)
  end, lines)
end

-- Puts quoted lines in the prompt at its cursor, leaves an empty line under them
-- to answer on, and goes there in insert mode.
local function insert_quote(lines)
  local buf, win = state.prompt.buf, state.prompt.win
  if #lines == 0 or not (buf and win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local current = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local block = vim.list_extend({}, lines)
  table.insert(block, "")
  local start
  if vim.trim(current) == "" then
    start = row - 1
    vim.api.nvim_buf_set_lines(buf, start, row, false, block)
  else
    table.insert(block, 1, "")
    start = row
    vim.api.nvim_buf_set_lines(buf, start, start, false, block)
  end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { start + #block, 0 })
  vim.cmd.startinsert()
end

-- The markdown block under the viewer's cursor: a list item, code block, table or
-- quote as a whole, otherwise the paragraph or heading.
local function block_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local table_at = state.shown.source[row + 1]
  if table_at then
    return vim.list_slice(state.shown.lines, table_at[1], table_at[2])
  end
  pcall(function()
    vim.treesitter.get_parser(0):parse()
  end)
  local ok, node = pcall(vim.treesitter.get_node, { pos = { row, 0 }, ignore_injections = true })
  local whole =
    { list_item = true, fenced_code_block = true, indented_code_block = true, pipe_table = true, block_quote = true }
  local fallback
  while ok and node do
    local kind = node:type()
    if whole[kind] then
      fallback = node
      break
    elseif not fallback and (kind == "paragraph" or kind:match("heading$")) then
      fallback = node
    elseif kind == "section" or kind == "document" then
      break
    end
    node = node:parent()
  end
  if not fallback then
    return vim.api.nvim_buf_get_lines(0, row, row + 1, false)
  end
  local srow, _, erow, ecol = fallback:range()
  return vim.api.nvim_buf_get_lines(0, srow, ecol == 0 and erow or erow + 1, false)
end

local function quote_block()
  insert_quote(quote_lines(block_at_cursor()))
end

-- Viewer rows from..to (1-based) as markdown: a drawn table touched by the range
-- comes back whole, as its pipe-table source.
---@return string[]
local function source_lines(from, to)
  local lines, last = {}, nil
  for row, line in ipairs(vim.api.nvim_buf_get_lines(state.viewer.buf, from - 1, to, false)) do
    local table_at = state.shown.source[from + row - 1]
    if not table_at then
      table.insert(lines, line)
    elseif not last or table_at[1] ~= last[1] then
      vim.list_extend(lines, vim.list_slice(state.shown.lines, table_at[1], table_at[2]))
    end
    last = table_at
  end
  return lines
end

-- A table drawn in the selection is quoted whole, as its markdown.
local function quote_selection()
  local from, to = vim.fn.line("v"), vim.fn.line(".")
  vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
  from, to = math.min(from, to), math.max(from, to)
  insert_quote(quote_lines((source_lines(from, to))))
end

-- A yank touching a drawn table copies its markdown instead of the box grid, so
-- pasted elsewhere it renders as a table, and no ~ pairs up across rows into a
-- strikethrough. The yank turns linewise, as a table is only whole in lines.
local function yank_source()
  local ev = vim.v.event
  if ev.operator ~= "y" or ev.visual and ev.regtype:sub(1, 1) == "\22" then
    return
  end
  local from, to = vim.fn.line("'["), vim.fn.line("']")
  local touched = false
  for row = from, to do
    touched = touched or state.shown.source[row] ~= nil
  end
  if not touched then
    return
  end
  local lines = source_lines(from, to)
  local regs = { ev.regname == "" and '"' or ev.regname }
  if ev.regname == "" then
    -- unnamed yanks also land in 0, and in + under clipboard=unnamedplus
    table.insert(regs, "0")
    if vim.o.clipboard:find("unnamedplus") then
      table.insert(regs, "+")
    elseif vim.o.clipboard:find("unnamed") then
      table.insert(regs, "*")
    end
  end
  for _, r in ipairs(regs) do
    vim.fn.setreg(r, lines, "V")
  end
end

-- The whole reply shown, for replying between its lines and deleting what doesn't
-- need an answer.
local function quote_all()
  local reply = state.replies[state.index]
  if not reply then
    return notify_error("No reply to quote yet")
  end
  insert_quote(quote_lines(vim.split(reply, "\n")))
end

-- Undoes the quotes once the replies are written: drops every quoted line, keeping
-- only the text typed between them. The blank lines the quotes left between replies
-- are squeezed to one, so the comments don't arrive spread over gaps.
local function unquote()
  local kept = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local blank = vim.trim(line) == ""
    if not line:match("^%s*>") and not (blank and (#kept == 0 or kept[#kept] == "")) then
      table.insert(kept, blank and "" or line)
    end
  end
  if kept[#kept] == "" then
    table.remove(kept)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, kept)
end

-- Quoted lines in the prompt are dimmed, so they read as context, not as what you
-- wrote; not italic, as the font's italic is a script. Claude still receives plain
-- `> ` markdown.
local function dim_quotes(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match("^%s*>") then
      vim.api.nvim_buf_set_extmark(
        buf,
        ns,
        i - 1,
        0,
        { end_col = #line, hl_group = "ClaudePromptQuote", priority = 110 }
      )
    end
  end
end

local function set_quote_hl()
  local fg = vim.api.nvim_get_hl(0, { name = "NonText", link = false }).fg
  vim.api.nvim_set_hl(0, "ClaudePromptQuote", { fg = fg })
end

------------------------------------------------------------------------------
-- History and templates

-- Every sent prompt, one JSON object a line, newest last.
local history_path = vim.fn.stdpath("state") .. "/claude-prompts.jsonl"
-- Reusable prompts, one .md file each, kept in this repo.
local templates_dir = vim.fn.stdpath("config") .. "/prompts"

local function record(text)
  vim.fn.mkdir(vim.fs.dirname(history_path), "p")
  local entry = vim.json.encode({ time = os.time(), cwd = vim.fn.getcwd(), text = text })
  vim.fn.writefile({ entry }, history_path, "a")
end

-- Puts text in the prompt at its cursor, replacing the prompt if it's empty, and
-- leaves the cursor in insert mode at the text's `$0`, if a template has one, or at its end.
local function insert_text(text)
  local buf, win = state.prompt.buf, state.prompt.win
  if not (buf and win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local lines = vim.split(vim.trim(text), "\n")
  local empty = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")) == ""
  local start
  if empty then
    start = 0
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    start = vim.api.nvim_win_get_cursor(win)[1]
    table.insert(lines, 1, "")
    vim.api.nvim_buf_set_lines(buf, start, start, false, lines)
  end
  local row, col, marked = start + #lines, #lines[#lines], false
  for i, line in ipairs(lines) do
    local at = line:find("$0", 1, true)
    if at then
      row, col, marked = start + i, at - 1, true
      vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { line:sub(1, at - 1) .. line:sub(at + 2) })
      break
    end
  end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { row, col })
  -- A marker at a line's end sits past its last character, which only append reaches.
  vim.cmd.startinsert({ bang = not marked or col >= #vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] })
end

local function pick_history()
  local items, seen = {}, {}
  local lines = vim.fn.filereadable(history_path) == 1 and vim.fn.readfile(history_path) or {}
  for i = #lines, 1, -1 do
    local ok, entry = pcall(vim.json.decode, lines[i])
    if ok and not seen[entry.text] then
      seen[entry.text] = true
      table.insert(items, {
        text = entry.text,
        when = os.date("%m-%d %H:%M", entry.time),
        where = vim.fn.fnamemodify(entry.cwd, ":t"),
        title = entry.text:match("[^\n]*"),
        preview = { text = entry.text, ft = "markdown" },
      })
    end
  end
  if #items == 0 then
    return notify_error("No sent prompts yet")
  end
  Snacks.picker.pick({
    title = "Sent Prompts",
    items = items,
    preview = "preview",
    format = function(item)
      return {
        { item.when, "Comment" },
        { " " },
        { ("%-12s"):format(item.where:sub(1, 12)), "Directory" },
        { " " },
        { item.title },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        insert_text(item.text)
      end
    end,
  })
end

local function pick_template()
  local items = {}
  for _, path in ipairs(vim.fn.glob(templates_dir .. "/*.md", false, true)) do
    table.insert(items, { text = vim.fn.fnamemodify(path, ":t:r"), file = path })
  end
  if #items == 0 then
    return notify_error("No templates in " .. templates_dir)
  end
  Snacks.picker.pick({
    title = "Prompt Templates",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item then
        insert_text(table.concat(vim.fn.readfile(item.file), "\n"))
      end
    end,
  })
end

------------------------------------------------------------------------------
-- Drafts

-- The prompt, saved as you type so a crash, reboot or power cut doesn't take it:
-- one file per Claude session, which herdr resumes under the same id after a
-- restart, so the next prefix+a in that tab brings it back; per pane until the
-- session exists. Deleted once sent or emptied.
local drafts_dir = vim.fn.stdpath("state") .. "/claude-drafts"

local function draft_path()
  local key = state.session or (vim.env.HERDR_PANE_ID and "pane-" .. vim.env.HERDR_PANE_ID:gsub(":", "-"))
  return key and ("%s/%s.md"):format(drafts_dir, key)
end

local function save_draft()
  local buf = state.prompt.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local path = draft_path()
  -- The session changed under the pane (/clear, a restarted Claude): follow it.
  if state.draft and state.draft ~= path then
    vim.fn.delete(state.draft)
  end
  state.draft = path
  if not path then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.trim(table.concat(lines, "\n")) == "" then
    vim.fn.delete(path)
    return
  end
  vim.fn.mkdir(drafts_dir, "p")
  -- Synced and renamed into place, so a power cut leaves the old draft or the new
  -- one, never half of one.
  local tmp = path .. ".tmp"
  if vim.fn.writefile(lines, tmp, "s") == 0 then
    vim.uv.fs_rename(tmp, path)
  end
end

local function schedule_save()
  state.save_timer = state.save_timer or vim.uv.new_timer()
  state.save_timer:start(500, 0, vim.schedule_wrap(save_draft))
end

-- Puts this session's saved draft in the prompt, above any unsent input
-- scripts/claude-prompt moved in from Claude.
local function restore_draft(buf)
  local path = draft_path()
  state.draft = path
  if not (path and vim.fn.filereadable(path) == 1) then
    return
  end
  local lines = vim.fn.readfile(path)
  local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.trim(table.concat(current, "\n")) ~= "" then
    table.insert(lines, "")
    vim.list_extend(lines, current)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

-- Every other saved draft, newest first: one whose pane is gone, or whose session
-- came back under a new id. Picking one moves it into this prompt.
local function pick_draft()
  local items, drafts, transcripts = {}, {}, {}
  for _, path in ipairs(vim.fn.glob(drafts_dir .. "/*.md", false, true)) do
    if path ~= state.draft then
      local key = vim.fn.fnamemodify(path, ":t:r")
      local transcript = vim.fn.glob("~/.claude*/projects/*/" .. key .. ".jsonl", false, true)[1]
      table.insert(drafts, { path = path, transcript = transcript })
      if transcript then
        table.insert(transcripts, transcript)
      end
    end
  end
  -- From the cwd each transcript records, since its project dir's name can't be read
  -- back: ~/dev/my-app is -home-me-dev-my-app.
  local cwds = require("config.prompt_stash").cwds_of(transcripts)
  for _, draft in ipairs(drafts) do
    local text = table.concat(vim.fn.readfile(draft.path), "\n")
    local time = vim.fn.getftime(draft.path)
    table.insert(items, {
      text = text,
      file = draft.path,
      time = time,
      when = os.date("%m-%d %H:%M", time),
      where = vim.fn.fnamemodify(draft.transcript and cwds[draft.transcript] or "", ":t"),
      title = text:match("[^\n]*"),
      preview = { text = text, ft = "markdown" },
    })
  end
  if #items == 0 then
    return notify_error("No other saved drafts")
  end
  table.sort(items, function(a, b)
    return a.time > b.time
  end)
  Snacks.picker.pick({
    title = "Saved Drafts",
    items = items,
    preview = "preview",
    format = function(item)
      return {
        { item.when, "Comment" },
        { " " },
        { ("%-16s"):format(item.where:sub(1, 16)), "Directory" },
        { " " },
        { item.title },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        insert_text(item.text)
        vim.fn.delete(item.file)
        save_draft()
      end
    end,
  })
end

-- Where config.prompt_ref finds this pane's nvim, keyed by the herdr pane it runs in.
-- Without the pane id's colon, which nvim would read as a TCP host:port.
function M.socket(pane_id)
  return ("%s/claude-prompt/%s.sock"):format(vim.env.XDG_RUNTIME_DIR or "/tmp", (pane_id:gsub(":", "-")))
end

-- Called over RPC by config.prompt_ref: puts a file reference at the end of the
-- prompt, on the last line if it has text, and leaves insert mode after it.
function M.add_ref(ref)
  local buf, win = state.prompt.buf, state.prompt.win
  if not (buf and win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local count = vim.api.nvim_buf_line_count(buf)
  local last = vim.api.nvim_buf_get_lines(buf, count - 1, count, false)[1]
  local line = vim.trim(last) == "" and ref or (last:gsub("%s+$", "") .. " " .. ref)
  vim.api.nvim_buf_set_lines(buf, count - 1, count, false, { line .. " " })
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { count, #line + 1 })
  vim.cmd.startinsert({ bang = true })
end

------------------------------------------------------------------------------
-- Stash (config/prompt_stash.lua)

-- Closes the agent and this pane, or their tab when nothing else is in it. This pane
-- goes last: closing it ends this nvim.
local function close_agent(agent)
  local listed = vim.system(list_panes(), { text = true }):wait()
  local ok, decoded = pcall(vim.json.decode, listed.stdout or "")
  local others = ok
      and #vim.tbl_filter(function(pane)
        return pane.tab_id == vim.env.HERDR_TAB_ID
          and pane.pane_id ~= agent.pane_id
          and pane.pane_id ~= vim.env.HERDR_PANE_ID
      end, vim.tbl_get(decoded, "result", "panes") or {})
    or 1
  if others == 0 then
    vim.system({ "herdr", "tab", "close", vim.env.HERDR_TAB_ID })
  else
    vim.system({ "herdr", "pane", "close", agent.pane_id }):wait()
    vim.system({ "herdr", "pane", "close", vim.env.HERDR_PANE_ID })
  end
end

-- Stashes this pane's session with the draft; with close, then closes the agent too,
-- the draft going with the stash rather than staying in claude-drafts.
local function stash(close)
  local agent, err = M.find_agent()
  local path, path_err = session_path(agent, err)
  if not path then
    return notify_error(path_err)
  end
  local buf = state.prompt.buf
  local draft = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  require("config.prompt_stash").add(agent.session, path, draft, function()
    if close then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      save_draft()
      close_agent(agent)
    end
  end)
end

local function pick_sessions()
  require("config.prompt_stash").pick(state.cwd)
end

------------------------------------------------------------------------------
-- Sending

-- `agent prompt` rather than `pane send-text`: it pastes, so newlines don't submit
-- early and Claude's vim mode can't run the text, and it refuses a blocked agent.
-- Claude only runs a command outside a long paste, which it reads as plain text, so a
-- command with arguments goes in as its own paste first. Bracketed by hand, since
-- `agent prompt` is the only paste herdr offers and it submits.
---@param item prompt.Item
---@param cb fun(err?: string)
local function send_item(agent, item, cb)
  local function prompt(text)
    vim.system(
      { "herdr", "agent", "prompt", agent.pane_id, text },
      { text = true },
      vim.schedule_wrap(function(sent)
        cb(sent.code ~= 0 and herdr_error(sent) or nil)
      end)
    )
  end
  if not (item.name and item.args) then
    return prompt(item.name or item.args)
  end
  vim.system(
    { "herdr", "pane", "send-text", agent.pane_id, "\27[200~" .. item.name .. " \27[201~" },
    { text = true },
    vim.schedule_wrap(function(pasted)
      if pasted.code ~= 0 then
        return cb(herdr_error(pasted))
      end
      prompt(item.args)
    end)
  )
end

local waiting_msg = "Claude is waiting on you (a dialog or permission prompt)"

-- Waits for a command to finish: /clear until Claude's session record names a new
-- session, anything else until Claude's input box is back. A command too quick to be
-- seen working counts as done once it has been idle for a second. Gives up after 10s,
-- so the next item goes anyway; calls back with the screen, "blocked" or "dialog", when
-- a prompt or dialog opens, or the input box stays gone for over a second.
---@param item prompt.Item
---@param before? string the session the command was sent in
---@param cb fun(screen?: "blocked"|"dialog", text?: string)
---@param alive fun(): boolean false once the queue is stopped, which ends the wait unanswered
local function await_item(item, before, cb, alive)
  local start, busy, stuck = vim.uv.now(), false, nil
  local function poll()
    if not alive() then
      return
    end
    read_screen(function(screen, agent, _, text)
      if not alive() then
        return
      end
      local now = vim.uv.now()
      local elapsed = now - start
      if screen == "blocked" then
        return cb(screen, text)
      end
      busy = busy or screen == "working"
      if screen == "dialog" then
        stuck = stuck or now
        if now - stuck >= 1000 then
          return cb(screen, text)
        end
      else
        stuck = nil
      end
      local done = screen == "idle"
        and (item.name == "/clear" and agent.session ~= before or item.name ~= "/clear" and (busy or elapsed >= 1000))
      if done or elapsed >= 10000 then
        return cb()
      end
      vim.defer_fn(poll, 250)
    end)
  end
  vim.defer_fn(poll, 250)
end

local answer_hint = "answer with <leader>ay yes, <leader>aY always, <leader>an no or <leader>a1-9"

-- Answers Claude's dialog from here: `choice` is checked against the options on its
-- screen first, so a dialog laid out differently, or none, only notifies.
---@param choice "yes"|"always"|"no"|integer
local function answer(choice)
  read_screen(function(screen, agent, err, text)
    if not screen then
      return notify_error(err)
    elseif screen == "dialog" then
      return notify_error("Claude's dialog isn't a question to answer from here; <leader>ac goes to its pane")
    elseif screen ~= "blocked" then
      return vim.notify("No dialog from Claude to answer", vim.log.levels.INFO, { title = "Claude prompt" })
    end
    state.status, state.screen = "blocked", text
    refresh() -- the call may have been written since the watcher last fired
    local call, options = pending_call()
    if not (call and options) then
      return notify_error("Couldn't read the options of Claude's dialog; answer it in Claude's pane (<leader>ac)")
    end
    local key, why = pending.key(options, choice)
    if not key then
      return notify_error(why)
    end
    local sent = vim.system({ "herdr", "pane", "send-keys", agent.pane_id, key }, { text = true }):wait()
    if sent.code ~= 0 then
      return notify_error(herdr_error(sent))
    end
    if call.screen then
      state.answered_screen = call.id
    else
      state.answered[call.id] = true
    end
    state.screen = nil
    update_pending()
  end)
end

-- Waits for an answerable dialog to close, answered from here or in Claude's pane.
---@param cb fun()
---@param alive fun(): boolean false once the queue is stopped, which ends the wait
local function wait_answered(cb, alive)
  if not alive() then
    return
  end
  read_screen(function(screen)
    if not alive() then
      return
    elseif screen == "blocked" or screen == "dialog" then
      return vim.defer_fn(function()
        wait_answered(cb, alive)
      end, 500)
    end
    cb()
  end)
end

-- Puts items the queue didn't send back in the draft, above anything typed since.
---@param items prompt.Item[]
local function put_back(items)
  local buf = state.prompt.buf
  if #items == 0 or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local lines = vim.split(
    table.concat(
      vim.tbl_map(function(item)
        return item.source
      end, items),
      "\n\n"
    ),
    "\n"
  )
  local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.trim(table.concat(current, "\n")) ~= "" then
    table.insert(lines, "")
    vim.list_extend(lines, current)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  save_draft()
end

-- Steps through the command queue in the background, each item once the one before
-- has finished, with its progress in the viewer's winbar. A dialog asking about a tool
-- call is answered from here, and one the prompt pane can't answer hands off to Claude's
-- pane (config.prompt_handoff); either holds the rest until it closes. A trip not taken
-- or abandoned, a refused send, or an interrupt (state.stop_queue) stops it, and what
-- isn't sent yet goes back in the draft. Every wait checks it's still running first.
---@param items prompt.Item[]
local function run_queue(items)
  local step
  local running, unsent = true, 1
  local function alive()
    return running
  end
  local function stop(from, why)
    if not running then
      return
    end
    running, state.queue, state.stop_queue = false, nil, nil
    set_winbars()
    put_back(vim.list_slice(items, from))
    notify_error(why .. (from <= #items and "; the rest is back in the draft" or ""))
  end
  state.stop_queue = function(why)
    stop(unsent, why)
  end
  -- Pauses at item `from` for a dialog, or stops there if no trip is taken.
  local function pause(agent, from, screen, text)
    if not handoff.wants(screen, text) then
      state.queue.label = state.queue.label .. " · waiting on you"
      state.status, state.screen = "blocked", text
      update_pending()
      vim.notify("Claude is waiting on you: " .. answer_hint, vim.log.levels.WARN, { title = "Claude prompt" })
      return wait_answered(function()
        step(from)
      end, alive)
    end
    handoff.go(agent, {
      armed = true,
      resume = function()
        step(from)
      end,
      abandon = function()
        stop(from, waiting_msg)
      end,
    }, function(went)
      if not running then
        return
      elseif went then
        state.queue.label = state.queue.label .. " · in Claude's pane"
        set_winbars()
      else
        stop(from, waiting_msg)
      end
    end)
  end
  step = function(i)
    if not running then
      return
    end
    unsent = i
    if i > #items then
      running, state.queue, state.stop_queue = false, nil, nil
      set_winbars()
      -- The session may have changed (/clear, a restarted Claude); follow it.
      return M.transcript_async(attach_to)
    end
    state.queue = { n = i, total = #items, label = queue.label(items[i]) }
    set_winbars()
    read_screen(function(screen, agent, err, text)
      if not running then
        return
      elseif not screen then
        return stop(i, err)
      elseif screen == "blocked" or screen == "dialog" then
        return pause(agent, i, screen, text)
      end
      send_item(agent, items[i], function(send_err)
        if not running then
          return
        elseif send_err then
          return stop(i, send_err)
        end
        unsent = i + 1
        if i == #items and not items[i].name then
          return step(i + 1)
        end
        -- A last command is awaited too, for the dialog it may open (/model).
        await_item(items[i], agent.session, function(opened, text)
          if opened then
            return pause(agent, i + 1, opened, text)
          end
          step(i + 1)
        end, alive)
      end)
    end)
  end
  step(1)
end

local function send()
  local buf = state.prompt.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
  if text == "" then
    return
  end
  if state.queue then
    return notify_error("Still sending the last command queue")
  end
  local items = queue.parse(text)
  local agent, err = M.find_agent()
  -- Refused while Claude waits on you: a dialog answerable here is shown, the rest hand
  -- off to its pane, sending once back.
  if agent and agent.agent_status == "blocked" then
    return read_screen(function(screen, now, _, text)
      if screen and not handoff.wants(screen, text) then
        state.status, state.screen = "blocked", text
        update_pending()
        return notify_error("Claude is waiting on you: " .. answer_hint)
      end
      handoff.go(now or agent, { armed = true, resume = send }, function(went)
        if not went then
          notify_error(waiting_msg)
        end
      end)
    end)
  end
  if agent and items[1].name then
    record(text)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    save_draft()
    return run_queue(items)
  end
  if not agent then
    return notify_error(err)
  end
  -- Cleared now, not once herdr answers, so what you type meanwhile isn't lost; a
  -- refused send goes back in the draft above it.
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  save_draft()
  vim.system(
    { "herdr", "agent", "prompt", agent.pane_id, text },
    { text = true },
    vim.schedule_wrap(function(sent)
      if sent.code ~= 0 then
        put_back({ { source = text } })
        return notify_error(herdr_error(sent) .. "; the prompt is back in the draft")
      end
      record(text)
      -- The session may have changed since open (a restarted Claude); follow it.
      M.transcript_async(attach_to)
    end)
  )
end

-- Interrupts Claude's turn, as Esc in its pane does, without leaving this one. A running
-- queue stops first, whatever it's waiting on, and what isn't sent yet goes back in the
-- draft; Claude is sent Esc only while it's working or has a dialog up. In vim mode an
-- Esc in insert mode only leaves it, so Claude's input mode, from the statusline it
-- shares, decides between one and two. The pending call clears once the interrupt
-- reaches the transcript.
local function interrupt()
  local had_queue = state.stop_queue ~= nil
  if had_queue then
    state.stop_queue("Interrupted")
  end
  read_screen(function(screen, agent, err)
    if not screen then
      return notify_error(err)
    elseif screen == "idle" then
      if not had_queue then
        vim.notify("Claude isn't working", vim.log.levels.INFO, { title = "Claude prompt" })
      end
      return
    end
    read_statusline(agent)
    local mode = vim.tbl_get(state.statusline or {}, "vim", "mode")
    local keys = { "herdr", "pane", "send-keys", agent.pane_id, "esc" }
    if type(mode) == "string" and mode:upper() ~= "NORMAL" then
      table.insert(keys, "esc")
    end
    local sent = vim.system(keys, { text = true }):wait()
    if sent.code ~= 0 then
      return notify_error(herdr_error(sent))
    end
    state.interrupted = true
    set_winbars()
    vim.defer_fn(function()
      state.interrupted = false
      set_winbars()
    end, 3000)
  end)
end

-- Cycles Claude's permission mode, as Shift+Tab in its pane does, in either vim mode of
-- its input. Not past a dialog, where Shift+Tab answers it instead. The footer is read
-- until it shows the change, so the bar has it at once.
local function cycle_mode()
  read_screen(function(screen, agent, err, text)
    if not screen then
      return notify_error(err)
    elseif screen == "blocked" or screen == "dialog" then
      return notify_error("Claude has a dialog up; answer it before cycling its mode")
    end
    local before = M.screen_mode(text)
    local sent = vim.system({ "herdr", "pane", "send-keys", agent.pane_id, "shift+tab" }, { text = true }):wait()
    if sent.code ~= 0 then
      return notify_error(herdr_error(sent))
    end
    local tries = 0
    local function check()
      tries = tries + 1
      read_mode(agent, function(mode)
        if (not mode or mode == before) and tries < 8 then
          vim.defer_fn(check, 150)
        end
      end)
    end
    vim.defer_fn(check, 100)
  end)
end

-- The hand-off on purpose: back on its own once Claude has opened a dialog and closed it.
-- Not while a queue runs, which hands off for its own dialogs.
local function to_claude()
  if state.queue then
    return notify_error("Still sending the command queue; it hands off at a dialog")
  end
  local agent, err = M.find_agent()
  if not agent then
    return notify_error(err)
  end
  handoff.go(agent, {}, function(went)
    if not went then
      notify_error("Already handed off, or this pane isn't focused in herdr")
    end
  end)
end

-- The transcript only exists once a session's first message is written, and
-- /clear or a restarted Claude moves to a new one, neither of which the file
-- watcher can see. So check the agent's session every few seconds, and re-read
-- too, in case libuv dropped an event. A failed lookup keeps the reply shown.
-- Claude going blocked mid-turn shows the pending call, or hands off to its pane for a
-- dialog the prompt pane can't answer; a running queue does its own.
local function start_polling()
  state.poll = state.poll or vim.uv.new_timer()
  state.poll:start(
    2000,
    2000,
    vim.schedule_wrap(function()
      M.transcript_async(function(path, _, agent)
        local was = state.status
        read_statusline(agent)
        locate(agent)
        if agent then
          read_mode(agent)
        end
        -- Read first, so the call Claude is blocked on is known.
        if path then
          attach_to(path)
        else
          set_winbars()
        end
        read_dialog(function(screen, now, text)
          if
            was ~= "blocked"
            and screen
            and not state.queue
            and not handoff.active()
            and handoff.wants(screen, text)
          then
            handoff.go(now, { armed = true })
          end
        end)
      end)
    end)
  )
end

------------------------------------------------------------------------------
-- Opening

-- The answers to Claude's dialog, in the draft and the viewer alike.
local function map_answers(buf)
  local function map(lhs, choice, desc)
    vim.keymap.set("n", lhs, function()
      answer(choice)
    end, { buffer = buf, desc = desc })
  end
  map("<leader>ay", "yes", "Yes to Claude's Dialog")
  map("<leader>aY", "always", "Yes, Don't Ask Again")
  map("<leader>an", "no", "No to Claude's Dialog")
  for n = 1, 9 do
    map("<leader>a" .. n, n, "Option " .. n .. " in Claude's Dialog")
  end
end

local function open_viewer(prompt_win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  -- snacks' smooth scroll animates the cursor too, so a quote taken mid-scroll
  -- would grab whatever line it was passing, and quick Alt+j presses get lost.
  vim.b[buf].snacks_scroll = false
  local height = math.floor(vim.o.lines * 0.62)
  local win = vim.api.nvim_open_win(buf, false, { split = "above", win = prompt_win, height = height })
  for opt, val in pairs(viewer_opts) do
    vim.wo[win][0][opt] = val
  end
  state.viewer = { buf = buf, win = win }

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<CR>", quote_block, "Quote Block into Prompt")
  map("x", "<CR>", quote_selection, "Quote Selection into Prompt")
  vim.api.nvim_create_autocmd("TextYankPost", { buffer = buf, callback = yank_source })
  map("n", "[r", function()
    step(-1)
  end, "Older Reply")
  map("n", "]r", function()
    step(1)
  end, "Newer Reply")
  map("n", "R", attach, "Reload Reply")
  map("n", "<leader>ak", toggle_tasks, "Claude's Tasks")
  map("n", "<leader>as", send, "Send Prompt to Claude")
  map("n", "<leader>ac", to_claude, "Claude's Pane")
  map("n", "<leader>ai", interrupt, "Interrupt Claude")
  map("n", "<leader>am", cycle_mode, "Cycle Permission Mode")
  map_answers(buf)
  -- The reply can't be edited, so insert keys move to the prompt and run there.
  for _, key in ipairs({ "i", "a", "I", "A", "o", "O" }) do
    map("n", key, function()
      local win = state.prompt.win
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_feedkeys(key, "n", false)
      end
    end, "Write in Prompt")
  end

  -- Files opened in the pane go to this window, the bigger one. Pickers take the
  -- window you used least recently, so from the reply a file lands in the prompt
  -- window; move it up here and put the draft back.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("claude_prompt_viewer", { clear = true }),
    callback = function(ev)
      local pwin = state.prompt.win
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      if vim.api.nvim_win_get_buf(win) == ev.buf then
        if ev.buf == buf then
          for opt, val in pairs(viewer_opts) do
            vim.wo[win][0][opt] = val
          end
          if state.unseen and state.view ~= "pending" then
            state.unseen = false
            show(#state.replies)
          else
            redraw()
            set_winbars()
          end
        else
          for opt in pairs(viewer_opts) do
            vim.wo[win][0][opt] = vim.go[opt]
          end
          vim.wo[win][0].winbar = "%#WinBar# 󰈙 %t%=%#Comment#<leader>ar reply "
        end
      elseif ev.buf ~= state.prompt.buf and pwin and vim.api.nvim_win_is_valid(pwin) then
        if vim.api.nvim_win_get_buf(pwin) ~= ev.buf then
          return
        end
        -- Scheduled so a picker's jump to the match has landed first.
        vim.schedule(function()
          if not (vim.api.nvim_win_is_valid(pwin) and vim.api.nvim_win_get_buf(pwin) == ev.buf) then
            return
          end
          local cursor = vim.api.nvim_win_get_cursor(pwin)
          vim.api.nvim_win_set_buf(pwin, state.prompt.buf)
          vim.api.nvim_win_set_buf(win, ev.buf)
          vim.api.nvim_set_current_win(win)
          pcall(vim.api.nvim_win_set_cursor, win, cursor)
          vim.cmd.normal({ "zz", bang = true })
        end)
      end
    end,
  })
end

-- Puts the reply back in the top window after a file covered it.
local function show_reply()
  local win = state.viewer.win
  if win and vim.api.nvim_win_is_valid(win) and not viewer_valid() then
    vim.api.nvim_win_set_buf(win, state.viewer.buf)
  end
end

-- Runs in the .md file scripts/claude-prompt opens, not an empty buffer: a file argument
-- is what skips the dashboard and makes LazyVim load its markdown autocmds in time.
function M.open()
  vim.fn.delete(vim.api.nvim_buf_get_name(0))
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.b[buf].claude_prompt = true -- turns on config.prompt_source
  state.prompt = { buf = buf, win = win }
  vim.wo[win][0].winfixheight = true
  local agent = M.find_agent()
  state.session = agent and agent.session
  restore_draft(buf)
  locate(agent)
  -- Before the first poll, for a Claude started in a mode that its transcript, not yet
  -- written, can't tell.
  if agent then
    read_mode(agent)
  end

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<leader>as", send, "Send Prompt to Claude")
  -- Global: it's needed from the file covering the reply. This nvim is the pane's alone.
  vim.keymap.set("n", "<leader>ar", show_reply, { desc = "Show Claude's Reply" })
  map("n", "<leader>aq", quote_all, "Quote Claude's Whole Reply")
  map("n", "<leader>aQ", unquote, "Strip Quoted Lines")
  map("n", "<leader>ah", pick_history, "Sent Prompts")
  map("n", "<leader>at", pick_template, "Prompt Templates")
  map("n", "<leader>ad", pick_draft, "Saved Drafts")
  map("n", "<leader>ak", toggle_tasks, "Claude's Tasks")
  map("n", "<leader>al", stash, "Stash Session")
  map("n", "<leader>aL", function()
    stash(true)
  end, "Stash Session and Close")
  map("n", "<leader>aH", pick_sessions, "Claude Sessions")
  map("n", "<leader>ac", to_claude, "Claude's Pane")
  map("n", "<leader>ai", interrupt, "Interrupt Claude")
  map("n", "<leader>am", cycle_mode, "Cycle Permission Mode")
  -- Beside the Alt scroll keys: interrupting is wanted mid-sentence, without leaving insert.
  map({ "n", "i" }, "<M-c>", interrupt, "Interrupt Claude")
  map_answers(buf)
  vim.api.nvim_create_user_command(
    "ClaudePane",
    to_claude,
    { desc = "Hand off to Claude's pane until its next dialog closes" }
  )
  -- Reachable by search too; this nvim is the pane's alone.
  vim.api.nvim_create_user_command("ClaudeStash", function(cmd)
    stash(cmd.bang)
  end, { bang = true, desc = "Stash this Claude session (! closes it)" })
  vim.api.nvim_create_user_command("ClaudeSessions", pick_sessions, { desc = "Pick a Claude session to resume" })
  map("n", "[r", function()
    step(-1)
  end, "Older Reply")
  map("n", "]r", function()
    step(1)
  end, "Newer Reply")
  -- Alt+j/k/u/d scroll as they do in WezTerm's scrollback, here the reply's.
  for lhs, keys in pairs({
    ["<M-j>"] = "<C-e>",
    ["<M-k>"] = "<C-y>",
    ["<M-d>"] = "<C-d>",
    ["<M-u>"] = "<C-u>",
    ["<M-g>"] = "gg",
    ["<M-G>"] = "G",
  }) do
    map({ "n", "i" }, lhs, scroll(keys), "Scroll Claude's Reply")
  end

  set_quote_hl()
  local group = vim.api.nvim_create_augroup("claude_prompt", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_quote_hl })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
    group = group,
    buffer = buf,
    callback = function()
      dim_quotes(buf)
    end,
  })
  vim.api.nvim_create_autocmd(
    { "TextChanged", "TextChangedI" },
    { group = group, buffer = buf, callback = schedule_save }
  )
  vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost", "VimLeavePre" }, { group = group, callback = save_draft })
  -- :q in the prompt closes the pane, not just the prompt window.
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    buffer = buf,
    callback = function()
      if state.viewer.win and vim.api.nvim_win_is_valid(state.viewer.win) then
        vim.api.nvim_win_close(state.viewer.win, true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = attach })
  -- Tables are drawn to the viewer's width, so redraw them when it changes.
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if vim.tbl_contains(vim.v.event.windows, state.viewer.win) then
        redraw()
      end
      -- So are the bars' hints.
      set_winbars()
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      redraw()
      set_winbars()
    end,
  })

  if vim.env.HERDR_PANE_ID then
    local sock = M.socket(vim.env.HERDR_PANE_ID)
    vim.fn.mkdir(vim.fs.dirname(sock), "p")
    vim.fn.delete(sock) -- left by a prompt pane that didn't exit cleanly
    pcall(vim.fn.serverstart, sock)
  end

  handoff.setup(read_screen, answerable)
  open_viewer(win)
  attach()
  start_polling()
  dim_quotes(buf)
  vim.cmd.normal({ "G", bang = true })
  vim.cmd.startinsert({ bang = true })
end

return M
