-- <leader>gi opens the issue this work belongs to as a buffer (Snacks.gh):
-- body and every comment, with a to comment, c to close, <CR> for labels and
-- the rest. LazyVim's own <leader>gi lists the issues of the git remote's
-- repo, which is empty where the tracker is a separate repo, and asks GitHub
-- again on every keystroke.
-- The tracker is the backlog project whose name is a directory on the cwd's
-- path (~/nixos/main -> nixos); the number is the one in the label of the
-- agent pane sharing this herdr tab ("#155 ..."), else the newest one the
-- branch's commits reference (owner/repo#155). With no number, the picker,
-- which <leader>gI opens outright, <leader>ga over closed issues too, and
-- <leader>gt and <leader>gm narrow to one label or milestone first.
-- Every list matches 168 or #168 by number as well as by title, filters typed
-- as field:value (state:closed label:bug milestone:!x), suggested as ghost
-- text while typed and taken with Tab, and Enter opens each issue selected
-- with Tab as its own buffer. In the milestone list, <c-x> closes one.
local M = {}

M.projects = vim.fn.expand("~/.config/backlog/projects.yaml")

--- The issue tracker for the working directory, as "owner/repo".
---@return string?
function M.repo()
  local ok, lines = pcall(vim.fn.readfile, M.projects)
  local cwd = assert(vim.uv.cwd()) .. "/"
  local name
  for _, line in ipairs(ok and lines or {}) do
    name = line:match("^%s*-%s*name:%s*(%S+)") or name
    local repo = line:match("^%s*repo:%s*(%S+)")
    if repo and name and cwd:find("/" .. name .. "/", 1, true) then
      return repo
    end
  end
end

--- The number of the issue being worked on here, if anything names one.
---@param repo string
---@return string?
function M.number(repo)
  local tab = vim.env.HERDR_TAB_ID
  if tab then
    local res = vim
      .system({ "herdr", "pane", "list", "--workspace", vim.env.HERDR_WORKSPACE_ID }, { text = true })
      :wait()
    local ok, json = pcall(vim.json.decode, res.stdout or "")
    for _, pane in ipairs(ok and json.result and json.result.panes or {}) do
      local n = pane.tab_id == tab and pane.agent and (pane.label or ""):match("#(%d+)")
      if n then
        return n
      end
    end
  end
  local log = vim.system({ "git", "log", "-20", "--format=%B", "main..HEAD" }, { text = true }):wait().stdout or ""
  return log:match(vim.pesc(repo) .. "#(%d+)")
end

-- Filters typed as field:value, as in Discord's search, each narrowing the
-- list (snacks' matcher reads item[field]). Values are matched fuzzily and
-- stored without spaces, so a completed value stays one word.
M.fields = { "state", "reason", "label", "milestone", "author" }

local function squash(s)
  return s and (s:gsub("%s+", "")) or nil
end

-- The milestone stays gh's { title } in the raw JSON, which snacks' issue view
-- draws; milestone: matches the squashed title, set on the item itself, which
-- the matcher reads before falling through to the JSON.
local function set_milestone(item, title)
  item.item.milestone = title and { title = title } or nil
  rawset(item, "milestone", squash(title))
end

-- snacks matches on text built from gh's raw JSON, which has no "#168" and
-- no label names: put them there, and keep them through later refetches.
local function searchable(item, ctx)
  local raw = item.item
  local known = type(raw.milestone) == "table" and raw.milestone.title or nil
  set_milestone(item, (ctx.picker.issue_milestones or {})[raw.number] or known)
  local labels = vim.tbl_map(function(l)
    return squash(l.name)
  end, raw.labels or {})
  raw.label = table.concat(labels, " ")
  raw.reason = item.state_reason
  raw.issue_text = ("#%d %s %s"):format(raw.number, raw.label, item.author or "")
  item.opts.text = { "issue_text", "title" }
  item.text = Snacks.picker.util.text(raw, item.opts.text)
end

-- gh issue list leaves milestones out of the fields snacks asks for, so they
-- come from a second call: filled into the items fetched by the time it
-- returns, and by the transform into those fetched after.
local function add_milestones(picker, opts)
  local cmd = { "gh", "issue", "list", "--state", opts.state or "open", "--limit", tostring(opts.limit) }
  vim.list_extend(
    cmd,
    { "--json", "number,milestone", "--jq", '.[] | select(.milestone) | "\\(.number)\t\\(.milestone.title)"' }
  )
  vim.list_extend(cmd, opts.repo and { "--repo", opts.repo } or {})
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or picker.closed then
        return
      end
      local by_number = {}
      for n, title in res.stdout:gmatch("(%d+)\t([^\n]+)") do
        by_number[tonumber(n)] = title
      end
      picker.issue_milestones = by_number
      for _, item in ipairs(picker.finder.items) do
        set_milestone(item, by_number[item.number])
      end
      picker:find({ refresh = false })
    end)
  end)
end

-- The values offered after field: are the ones the fetched issues carry.
local function values(picker, field)
  if field == "state" then
    return { "open", "closed" }
  elseif field == "reason" then
    return { "completed", "not_planned" }
  end
  local seen, ret = {}, {}
  local function add(v)
    if v and v ~= "" and not seen[v] then
      seen[v], ret[#ret + 1] = true, v
    end
  end
  if field == "milestone" then
    vim.iter(pairs(picker.issue_milestones or {})):each(function(_, v)
      add(squash(v))
    end)
  end
  for _, item in ipairs(picker.finder.items) do
    if field == "label" then
      vim.iter(vim.split(item.item.label or "", " ")):each(add)
    elseif field == "author" then
      add(item.author)
    end
  end
  table.sort(ret)
  return ret
end

local ns = vim.api.nvim_create_namespace("issue_filter_hint")

-- The suggestion shows as ghost text after the cursor, the chosen one's rest
-- then the others, where a completion menu would cover what's typed.
local function show(picker)
  local buf, hint = picker.input.win.buf, picker.issue_hint
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not hint then
    return
  end
  local chunks = { { hint.words[hint.idx]:sub(hint.typed + 1), "Comment" } }
  local others = {}
  for i, w in ipairs(hint.words) do
    if i ~= hint.idx and #others < 5 then
      others[#others + 1] = w
    end
  end
  if #others > 0 then
    chunks[#chunks + 1] = { "  " .. table.concat(others, " "), "NonText" }
  end
  vim.api.nvim_buf_set_extmark(buf, ns, 0, hint.col, { virt_text = chunks, virt_text_pos = "inline" })
end

-- Suggest a field name for a word typed at a prefix of one, and the values
-- after field: (field:!value negates the filter, as snacks reads it).
local function suggest(picker)
  local col = vim.api.nvim_win_get_cursor(picker.input.win.win)[2]
  local line = vim.api.nvim_buf_get_lines(picker.input.win.buf, 0, 1, false)[1]:sub(1, col)
  local token = line:match("(%S*)$")
  local field, bang, value = token:match("^(%a+):(!?)(%S*)$")
  local typed, words = token, {}
  if field and vim.tbl_contains(M.fields, field) then
    typed = value
    for _, v in ipairs(values(picker, field)) do
      if v ~= value and vim.startswith(v:lower(), value:lower()) then
        words[#words + 1] = v
      end
    end
  elseif not field and token:match("^%a+$") then
    for _, f in ipairs(M.fields) do
      if vim.startswith(f, token:lower()) then
        words[#words + 1] = f .. ":"
      end
    end
  end
  picker.issue_hint = #words > 0
      and vim.fn.mode():sub(1, 1) == "i"
      and { col = col, typed = #typed, words = words, idx = 1 }
    or nil
  show(picker)
end

local function hint_keys(picker)
  vim.api.nvim_create_autocmd({ "TextChangedI", "CursorMovedI", "InsertLeave" }, {
    buffer = picker.input.win.buf,
    callback = function()
      suggest(picker)
    end,
  })
end

-- Tab takes the suggestion, replacing what's typed of it; with none, it
-- selects as snacks' Tab does.
local function accept(picker)
  local hint = picker.issue_hint
  if not hint then
    return picker:action("select_and_next")
  end
  local word = hint.words[hint.idx]
  local win = picker.input.win.win
  vim.api.nvim_buf_set_text(picker.input.win.buf, 0, hint.col - hint.typed, 0, hint.col, { word })
  vim.api.nvim_win_set_cursor(win, { 1, hint.col - hint.typed + #word })
  suggest(picker) -- state: taken: now its values
end

-- Ctrl+N/P cycle through the suggestions, or move in the list without one.
local function cycle(step, fallback)
  return function(picker)
    local hint = picker.issue_hint
    if not hint then
      return picker:action(fallback)
    end
    hint.idx = (hint.idx - 1 + step) % #hint.words + 1
    show(picker)
  end
end

-- Enter opens every issue selected with Tab, else the actions of the one under
-- the cursor, as snacks does.
local function confirm(picker, item, action)
  if #picker:selected() > 0 then
    return Snacks.picker.actions.jump(picker, item, action)
  end
  return picker:action("gh_actions")
end

--- The tracker's open issues, fetched once and filtered locally.
---@param opts? snacks.picker.gh.issue.Config
function M.pick(opts)
  -- Outside a backlog project, the remote's repo, as LazyVim's bind did. The
  -- limit is above the backlog's size: the filter only sees what was fetched.
  opts = vim.tbl_extend("force", {
    repo = M.repo(),
    live = false,
    limit = 200,
    transform = searchable,
    confirm = confirm,
    on_show = hint_keys,
    actions = {
      issue_tab = accept,
      issue_down = cycle(1, "list_down"),
      issue_up = cycle(-1, "list_up"),
    },
    win = {
      input = {
        keys = {
          ["<Tab>"] = { "issue_tab", mode = { "i", "n" } },
          ["<c-n>"] = { "issue_down", mode = { "i", "n" } },
          ["<c-p>"] = { "issue_up", mode = { "i", "n" } },
        },
      },
    },
  }, opts or {})
  local picker = Snacks.picker.gh_issue(opts)
  add_milestones(picker, opts)
end

--- Open and closed issues alike; the status icon tells them apart. Closed
--- issues pile up, so the limit is higher.
function M.all()
  M.pick({ state = "all", limit = 1000, title = "  Issues · all" })
end

--- Pick one of the labels the tracker's open issues carry, most used first,
--- then its issues. A label on none of them isn't offered: its list is empty.
function M.by_label()
  local repo = M.repo()
  local jq = '[.[].labels[].name] | group_by(.) | sort_by(-length)[] | "\\(.[0])\t\\(length)"'
  local cmd = { "gh", "issue", "list", "--state", "open", "--limit", "200", "--json", "labels", "--jq", jq }
  vim.list_extend(cmd, repo and { "--repo", repo } or {})
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return Snacks.notify.error(vim.trim(res.stderr or "gh issue list failed"))
      end
      local labels = vim.split(vim.trim(res.stdout), "\n", { trimempty = true })
      vim.ui.select(labels, {
        prompt = "Issues labelled",
        format_item = function(line)
          return (line:gsub("\t", "  "))
        end,
      }, function(line)
        local label = line and line:match("^[^\t]+")
        if label then
          M.pick({ label = label, title = "  Issues · " .. label })
        end
      end)
    end)
  end)
end

--- Pick one of the tracker's open milestones, by open-issue count, then its
--- open issues; one with none open lists its closed ones too. <c-x> closes
--- the milestone under the cursor, after asking.
function M.by_milestone()
  local api = ("repos/%s/milestones"):format(M.repo() or "{owner}/{repo}")
  local jq = 'sort_by(-.open_issues)[] | "\\(.number)\t\\(.open_issues)\t\\(.title)"'
  local res = vim.system({ "gh", "api", api .. "?state=open&per_page=100", "--jq", jq }, { text = true }):wait()
  if res.code ~= 0 then
    return Snacks.notify.error(vim.trim(res.stderr or "gh api milestones failed"))
  end
  local items = {}
  for number, open, title in res.stdout:gmatch("(%d+)\t(%d+)\t([^\n]+)") do
    items[#items + 1] = { text = title, number = number, open = tonumber(open) }
  end
  Snacks.picker({
    title = "Milestones",
    items = items,
    layout = { preset = "select" },
    format = function(item)
      return { { item.text }, { ("  %d open"):format(item.open), "SnacksPickerComment" } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.pick({
          milestone = item.text,
          state = item.open == 0 and "all" or "open",
          title = "  Issues · " .. item.text,
        })
      end
    end,
    actions = {
      close_milestone = {
        desc = "Close milestone",
        action = function(picker, item)
          if not item then
            return
          end
          local open = item.open > 0 and (" (%d issues still open)"):format(item.open) or ""
          Snacks.picker.select({ "No", "Yes" }, { prompt = ("Close %s%s?"):format(item.text, open) }, function(yes)
            if yes ~= "Yes" then
              return
            end
            local cmd = { "gh", "api", "-X", "PATCH", api .. "/" .. item.number, "-f", "state=closed", "--silent" }
            vim.system(cmd, { text = true }, function(r)
              vim.schedule(function()
                if r.code ~= 0 then
                  return Snacks.notify.error(vim.trim(r.stderr or "closing the milestone failed"))
                end
                Snacks.notify.info("Closed milestone " .. item.text)
                for i, it in ipairs(items) do
                  if it == item then
                    table.remove(items, i)
                  end
                end
                if not picker.closed then
                  picker:find({ refresh = true })
                end
              end)
            end)
          end)
        end,
      },
    },
    win = {
      input = { keys = { ["<c-x>"] = { "close_milestone", mode = { "i", "n" } } } },
      list = { keys = { ["<c-x>"] = "close_milestone" } },
    },
  })
end

--- Open this work's issue, or the picker when nothing names one.
function M.open()
  local repo = M.repo()
  local n = repo and M.number(repo)
  if n then
    vim.cmd.edit(("gh://%s/issue/%s"):format(repo, n))
  else
    M.pick()
  end
end

return M
