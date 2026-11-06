-- Prompt pane: a scratch buffer for writing to the Claude agent in the same herdr tab,
-- with Claude's last reply rendered in a read-only window above it, so you can read,
-- scroll and quote the reply while composing. Opened by the `prefix+a` command in
-- herdr/.config/herdr/config.toml, through scripts/claude-prompt.
local M = {}

local tables = require("config.prompt_table")

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
  replies = {}, -- finished replies, oldest first
  index = 0, -- the one shown; 0 when there are none
  view = "reply", -- or "tasks", the task list shown in its place
  tasks = {}, -- Claude's task list: { id?, subject, status }
  activity = nil, -- the tool call Claude made last, while a turn runs
  watcher = nil,
  timer = nil,
}

-- herdr prints errors as JSON on stderr; fall back to the raw text for anything else.
local function herdr_error(result)
  local ok, decoded = pcall(vim.json.decode, result.stderr)
  return ok and vim.tbl_get(decoded, "error", "message") or vim.trim(result.stderr)
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
  return agents[1]
end

local function list_panes()
  return { "herdr", "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID }
end

-- Looked up on every send, not at open, so restarting Claude doesn't strand the pane.
function M.find_agent()
  return pick_agent(vim.system(list_panes(), { text = true }):wait())
end

---@return string? path of the agent's session transcript
---@return string? err
local function session_path(agent, err)
  local session = agent and vim.tbl_get(agent, "agent_session", "value")
  if not session then
    return nil, err or "Claude has no session yet"
  end
  local path = vim.fn.glob("~/.claude/projects/*/" .. session .. ".jsonl", false, true)[1]
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

-- Parses whatever was appended since the last read, so a long session isn't
-- re-read on every write. Returns whether a new reply arrived.
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

  local before, last_id = #state.replies, state.last_id
  for line in text:gmatch("[^\n]+") do
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
          local body = table.concat(texts, "\n")
          -- A message's content blocks arrive as separate entries; join them.
          if entry.message.id and entry.message.id == last_id then
            state.replies[#state.replies] = state.replies[#state.replies] .. "\n" .. body
          else
            table.insert(state.replies, body)
          end
          last_id = entry.message.id
          state.activity = nil
        end
      end
    end
  end
  state.last_id = last_id
  return #state.replies > before
end

------------------------------------------------------------------------------
-- Viewer

local function viewer_valid()
  return state.viewer.win and vim.api.nvim_win_is_valid(state.viewer.win)
end

-- What Claude's own statusline would show, hidden under the zoomed pane: its state
-- from herdr, and context and 5h usage from the render ~/.claude/statusline.sh shares.
local status_hl =
  { working = "DiagnosticWarn", blocked = "DiagnosticError", idle = "DiagnosticOk", done = "DiagnosticOk" }

local function pct_hl(pct)
  return pct >= 80 and "DiagnosticError" or pct >= 50 and "DiagnosticWarn" or "Comment"
end

-- Time until a rate limit resets, as "2d3h", "2h05m" or "47m", like the statusline's.
local function until_reset(at)
  local left = math.max(0, (tonumber(at) or 0) - os.time())
  local d, h, m = math.floor(left / 86400), math.floor(left % 86400 / 3600), math.floor(left % 3600 / 60)
  return d > 0 and ("%dd%dh"):format(d, h) or h > 0 and ("%dh%02dm"):format(h, m) or ("%dm"):format(m)
end

local function status_line()
  local parts = {}
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
  -- Coloured by use, counting down to the reset. resets_at is epoch seconds; an
  -- ISO time from an older Claude just leaves the countdown out.
  for _, limit in ipairs({ { "five_hour", "5h" }, { "seven_day", "wk" } }) do
    local rl = vim.tbl_get(info, "rate_limits", limit[1]) or {}
    if rl.used_percentage then
      local reset = tonumber(rl.resets_at) and (" " .. until_reset(rl.resets_at)) or ""
      table.insert(parts, ("%%#%s#%s %d%%%%%s"):format(pct_hl(rl.used_percentage), limit[2], rl.used_percentage, reset))
    end
  end
  return #parts > 0 and ("%#Comment# · " .. table.concat(parts, "%#Comment# · ")) or ""
end

-- Re-read on every poll; a missing file (a Claude without the shared statusline)
-- just leaves those parts out.
local function read_statusline(agent)
  local session = agent and vim.tbl_get(agent, "agent_session", "value")
  local path = session and ("%s/claude-statusline/%s.json"):format(vim.env.XDG_RUNTIME_DIR or "/tmp", session)
  local ok, info = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  state.status = agent and agent.agent_status
  state.statusline = ok and info or nil
end

local function set_winbars()
  if viewer_valid() then
    local done = #vim.tbl_filter(function(task)
      return task.status == "completed"
    end, state.tasks)
    local tasks = #state.tasks > 0 and ("tasks %d/%d"):format(done, #state.tasks)
    local title = state.view == "tasks" and ("Claude · " .. (tasks or "no tasks"))
      or state.index > 0 and ("Claude · reply %d/%d"):format(state.index, #state.replies)
      or "Claude · no reply yet"
    if state.view ~= "tasks" and tasks then
      title = title .. " · " .. tasks
    end
    vim.wo[state.viewer.win].winbar = "%#WinBar# 󰚩 "
      .. title
      .. status_line()
      .. "%=%#Comment#[r ]r older/newer · <CR> quote · <leader>ak tasks "
  end
  if state.prompt.win and vim.api.nvim_win_is_valid(state.prompt.win) then
    vim.wo[state.prompt.win].winbar =
      "%#WinBar# 󰏫 Prompt%=%#Comment#M-j/k M-u/d scroll reply · <leader>ah history · <leader>at template · <leader>as send "
  end
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

local function toggle_tasks()
  if state.view == "tasks" then
    show(state.index)
  else
    show_tasks()
  end
end

-- Picks up new replies and tasks. Following the newest reply unless you've stepped
-- back to an older one; the task list stays up when one arrives, redrawn as it changes.
local function refresh()
  local following = state.index == #state.replies
  local new_reply = read_new()
  if state.view == "tasks" then
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
  else
    set_winbars()
  end
  state.tasks_changed = false
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
  state.tasks, state.activity = {}, nil
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

-- The transcript only exists once a session's first message is written, and
-- /clear or a restarted Claude moves to a new one, neither of which the file
-- watcher can see. So check the agent's session every few seconds, and re-read
-- too, in case libuv dropped an event. A failed lookup keeps the reply shown.
local function start_polling()
  state.poll = state.poll or vim.uv.new_timer()
  state.poll:start(
    2000,
    2000,
    vim.schedule_wrap(function()
      M.transcript_async(function(path, _, agent)
        read_statusline(agent)
        if path then
          attach_to(path)
        else
          set_winbars()
        end
      end)
    end)
  )
end

local function step(delta)
  local target = state.index + delta
  if target >= 1 and target <= #state.replies then
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

-- A table drawn in the selection is quoted whole, as its markdown.
local function quote_selection()
  local from, to = vim.fn.line("v"), vim.fn.line(".")
  vim.cmd.normal({ vim.keycode("<Esc>"), bang = true })
  from, to = math.min(from, to), math.max(from, to)
  local lines, last = {}, nil
  for row, line in ipairs(vim.api.nvim_buf_get_lines(0, from - 1, to, false)) do
    local table_at = state.shown.source[from + row - 1]
    if not table_at then
      table.insert(lines, line)
    elseif table_at ~= last then
      vim.list_extend(lines, vim.list_slice(state.shown.lines, table_at[1], table_at[2]))
    end
    last = table_at
  end
  insert_quote(quote_lines(lines))
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
-- Sending

local function send()
  local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  if text == "" then
    return
  end
  local text_sent = text -- whole, before a leading /skill is split off
  local agent, err = M.find_agent()
  if agent then
    -- Claude only runs a leading /skill outside a long paste, which it reads as plain
    -- text, so that word goes in as its own paste. Bracketed by hand, since `agent prompt`
    -- is the only paste herdr offers and it submits. A blocked agent would be left with
    -- the word in its input, so that case falls through for `agent prompt` to refuse.
    local skill, rest = text:match("^(/[%w:_-]+)%s+(.+)$")
    if skill and agent.agent_status ~= "blocked" then
      vim.system({ "herdr", "pane", "send-text", agent.pane_id, "\27[200~" .. skill .. " \27[201~" }):wait()
      text = rest
    end
    -- `agent prompt` rather than `pane send-text`: it pastes, so newlines don't submit
    -- early and Claude's vim mode can't run the text, and it refuses a blocked agent.
    local sent = vim.system({ "herdr", "agent", "prompt", agent.pane_id, text }, { text = true }):wait()
    err = sent.code ~= 0 and herdr_error(sent) or nil
  end
  if err then
    return notify_error(err)
  end
  record(text_sent)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  -- The session may have changed since open (a restarted Claude); follow it.
  attach()
end

------------------------------------------------------------------------------
-- Opening

local function open_viewer(prompt_win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  -- snacks' smooth scroll animates the cursor too, so a quote taken mid-scroll
  -- would grab whatever line it was passing, and quick Alt+j presses get lost.
  vim.b[buf].snacks_scroll = false
  local height = math.floor(vim.o.lines * 0.62)
  local win = vim.api.nvim_open_win(buf, false, { split = "above", win = prompt_win, height = height })
  for opt, val in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    wrap = true,
    linebreak = true,
  }) do
    vim.wo[win][opt] = val
  end
  state.viewer = { buf = buf, win = win }

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<CR>", quote_block, "Quote Block into Prompt")
  map("x", "<CR>", quote_selection, "Quote Selection into Prompt")
  map("n", "[r", function()
    step(-1)
  end, "Older Reply")
  map("n", "]r", function()
    step(1)
  end, "Newer Reply")
  map("n", "R", attach, "Reload Reply")
  map("n", "<leader>ak", toggle_tasks, "Claude's Tasks")
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
  vim.wo[win].winfixheight = true

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<leader>as", send, "Send Prompt to Claude")
  map("n", "<leader>aq", quote_all, "Quote Claude's Whole Reply")
  map("n", "<leader>aQ", unquote, "Strip Quoted Lines")
  map("n", "<leader>ah", pick_history, "Sent Prompts")
  map("n", "<leader>at", pick_template, "Prompt Templates")
  map("n", "<leader>ak", toggle_tasks, "Claude's Tasks")
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
  -- :q in the prompt closes the pane, not just the prompt window.
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    buffer = buf,
    callback = function()
      if viewer_valid() then
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
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = redraw })

  if vim.env.HERDR_PANE_ID then
    local sock = M.socket(vim.env.HERDR_PANE_ID)
    vim.fn.mkdir(vim.fs.dirname(sock), "p")
    vim.fn.delete(sock) -- left by a prompt pane that didn't exit cleanly
    pcall(vim.fn.serverstart, sock)
  end

  open_viewer(win)
  attach()
  start_polling()
  dim_quotes(buf)
  vim.cmd.normal({ "G", bang = true })
  vim.cmd.startinsert({ bang = true })
end

return M
