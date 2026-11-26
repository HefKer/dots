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
-- An issue with an open blocker has a lock before its title (blocked:yes
-- lists them, blocking:yes those holding up an open one), and its buffer
-- shows Blocked by, Blocking, Parent and Sub-issues rows, whose #n (or
-- owner/repo#n, across trackers) Enter or gf opens.
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
M.fields = { "state", "reason", "label", "milestone", "author", "blocked", "blocking" }

local function squash(s)
  return s and (s:gsub("%s+", "")) or nil
end

-- The milestone stays gh's { title } in the raw JSON, which snacks' issue view
-- draws; milestone: matches the squashed title, set on the item itself, which
-- the matcher reads before falling through to the JSON. blocked: and
-- blocking: are yes or no, set there too, from what the list call found.
local function set_extra(item, extra)
  local title = extra and extra.milestone
  item.item.milestone = title and { title = title } or nil
  rawset(item, "milestone", squash(title))
  rawset(item, "blocked", extra and (extra.blocked and "yes" or "no") or nil)
  rawset(item, "blocking", extra and (extra.blocking and "yes" or "no") or nil)
end

-- snacks matches on text built from gh's raw JSON, which has no "#168" and
-- no label names: put them there, and keep them through later refetches.
local function searchable(item, ctx)
  local raw = item.item
  local extra = (ctx.picker.issue_extra or {})[raw.number]
  if not extra and type(raw.milestone) == "table" then
    extra = { milestone = raw.milestone.title }
  end
  set_extra(item, extra)
  local labels = vim.tbl_map(function(l)
    return squash(l.name)
  end, raw.labels or {})
  raw.label = table.concat(labels, " ")
  raw.reason = item.state_reason
  raw.issue_text = ("#%d %s %s"):format(raw.number, raw.label, item.author or "")
  item.opts.text = { "issue_text", "title" }
  item.text = Snacks.picker.util.text(raw, item.opts.text)
end

-- gh issue list leaves milestones and blockers out of the fields snacks asks
-- for, so they come from a second call, made each time the list is fetched:
-- filled into the items fetched by the time it returns, and by the transform
-- into those fetched after. Only open blockers and blocked issues count.
local extra_jq = '.[] | "\\(.number)\t\\(.milestone.title // "")\t'
  .. '\\([.blockedBy.nodes[] | select(.state == "OPEN")] | length)\t'
  .. '\\([.blocking.nodes[] | select(.state == "OPEN")] | length)"'

local function add_extra(picker, opts)
  local cmd = { "gh", "issue", "list", "--state", opts.state or "open", "--limit", tostring(opts.limit) }
  vim.list_extend(cmd, { "--json", "number,milestone,blockedBy,blocking", "--jq", extra_jq })
  vim.list_extend(cmd, opts.label and { "--label", opts.label } or {})
  vim.list_extend(cmd, opts.milestone and { "--milestone", opts.milestone } or {})
  vim.list_extend(cmd, opts.repo and { "--repo", opts.repo } or {})
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or picker.closed then
        return
      end
      local by_number = {}
      for n, title, blocked, blocking in res.stdout:gmatch("(%d+)\t([^\t]*)\t(%d+)\t(%d+)") do
        by_number[tonumber(n)] = {
          milestone = title ~= "" and title or nil,
          blocked = blocked ~= "0",
          blocking = blocking ~= "0",
        }
      end
      picker.issue_extra = by_number
      for _, item in ipairs(picker.finder.items) do
        set_extra(item, by_number[item.number])
      end
      picker:find({ refresh = false })
    end)
  end)
end

-- snacks' issue finder, with the second call started alongside each run, so
-- a refetch drops the lock of an issue whose last blocker has closed.
local function finder(opts, ctx)
  add_extra(ctx.picker, opts)
  return require("snacks.picker.source.gh").issue(opts, ctx)
end

-- snacks' issue row, with a lock before the title of a blocked issue.
local function format(item, picker)
  local ret = require("snacks.picker.source.gh").format(item, picker)
  if rawget(item, "blocked") == "yes" then
    for i, chunk in ipairs(ret) do
      if item.hash and vim.trim(chunk[1] or "") == item.hash then
        table.insert(ret, i + 1, { "󰌾 ", "DiagnosticWarn" })
        break
      end
    end
  end
  return ret
end

-- The values offered after field: are the ones the fetched issues carry.
local function values(picker, field)
  if field == "state" then
    return { "open", "closed" }
  elseif field == "reason" then
    return { "completed", "not_planned" }
  elseif field == "blocked" or field == "blocking" then
    return { "yes", "no" }
  end
  local seen, ret = {}, {}
  local function add(v)
    if v and v ~= "" and not seen[v] then
      seen[v], ret[#ret + 1] = true, v
    end
  end
  if field == "milestone" then
    vim.iter(pairs(picker.issue_extra or {})):each(function(_, v)
      add(squash(v.milestone))
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
    finder = finder,
    format = format,
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
  Snacks.picker.gh_issue(opts)
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

-- The issue buffer's relation rows, drawn from fields its view asks gh for.
-- gh gives each relation as { nodes, totalCount }; snacks' own list keeps them
-- unfetched, so a buffer opened from the picker asks for them too.
M.view_fields = { "milestone", "blockedBy", "blocking", "parent", "subIssues", "subIssuesSummary" }

local function nodes(v)
  return type(v) == "table" and (v.nodes or v) or {}
end

local function is_open(node)
  return (node.state or ""):lower() == "open"
end

-- #n for an issue in the buffer's own tracker, owner/repo#n for another's.
local function ref(item, node)
  local repo = node.url and require("snacks.gh.item").get_repo(node.url)
  if repo and repo:lower() ~= (item.repo or ""):lower() then
    return ("%s#%d"):format(repo:lower(), node.number)
  end
  return "#" .. node.number
end

local function refs(item, list)
  local ret = {}
  for _, node in ipairs(list) do
    if #ret > 0 then
      ret[#ret + 1] = { " " }
    end
    ret[#ret + 1] = { ref(item, node), "@markup.link" }
  end
  return ret
end

local function open_ones(item, field)
  return refs(item, vim.tbl_filter(is_open, nodes(item.item[field])))
end

M.props = {
  {
    name = "Blocked by",
    hl = function(item)
      return open_ones(item, "blockedBy")
    end,
  },
  {
    name = "Blocking",
    hl = function(item)
      return open_ones(item, "blocking")
    end,
  },
  {
    name = "Parent",
    hl = function(item)
      local parent = item.item.parent
      if type(parent) == "table" and parent.number then
        return { { ref(item, parent), "@markup.link" }, { " " .. (parent.title or "") } }
      end
    end,
  },
  {
    name = "Sub-issues",
    hl = function(item)
      local sum = item.item.subIssuesSummary
      if type(sum) ~= "table" or (sum.total or 0) == 0 then
        return
      end
      local ret = { { ("%d/%d done"):format(sum.completed or 0, sum.total), "SnacksPickerComment" } }
      local open = open_ones(item, "subIssues")
      if #open > 0 then
        ret[#ret + 1] = { " " }
        vim.list_extend(ret, open)
      end
      return ret
    end,
  },
}

-- The ref under the cursor in a relation row; in Parent, only the parent's
-- (its title may hold others).
local function ref_at_cursor(item)
  local line = vim.api.nvim_get_current_line()
  local row = line:match("^(%a[%a%- ]*):")
  local names = vim.tbl_map(function(p)
    return p.name
  end, M.props)
  if not vim.tbl_contains(names, row) then
    return
  end
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local start = #row + 2
  while true do
    local s, e = line:find("[%w%.%-_]*/?[%w%.%-_]*#%d+", start)
    if not s then
      return
    end
    if row == "Parent" or (col >= s and col <= e) then
      local repo, n = line:sub(s, e):match("^(.-)#(%d+)$")
      return repo ~= "" and repo or item.repo, n
    end
    start = e + 1
  end
end

--- Enter or gf in an issue buffer: open the related issue under the cursor,
--- else do what the key does there already.
---@param fallback fun(item: table)
function M.follow(fallback)
  return function(item)
    local repo, n = ref_at_cursor(item)
    if repo then
      return vim.cmd.edit(("gh://%s/issue/%s"):format(repo, n))
    end
    fallback(item)
  end
end

--- Teach snacks' issue view the relation rows: added after Milestone, and
--- their fields added to what its view fetches. Safe to run again.
function M.setup()
  local Render = require("snacks.gh.render")
  Render.props = vim.tbl_filter(function(p)
    return not p.issue_relation
  end, Render.props)
  local at = #Render.props + 1
  for i, p in ipairs(Render.props) do
    if p.name == "Milestone" then
      at = i + 1
    end
  end
  for i, p in ipairs(M.props) do
    p.issue_relation = true
    table.insert(Render.props, at + i - 1, p)
  end
  local Api = require("snacks.gh.api")
  Api.issue_view = Api.issue_view or Api.view
  Api.view = function(cb, item, opts)
    if item.type == "issue" then
      opts = vim.tbl_extend("force", opts or {}, {
        fields = vim.list_extend(vim.deepcopy(opts and opts.fields or {}), M.view_fields),
      })
    end
    return Api.issue_view(cb, item, opts)
  end
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
