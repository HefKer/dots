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
-- Every list matches 168 or #168 by number as well as by title, and Enter
-- opens each issue selected with Tab as its own buffer.
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

-- snacks matches on text built from gh's raw JSON, which has no "#168" and
-- no label names: put them there, and keep them through later refetches.
local function searchable(item)
  local raw = item.item
  local labels = vim.tbl_map(function(l)
    return l.name
  end, raw.labels or {})
  raw.issue_text = ("#%d %s %s"):format(raw.number, table.concat(labels, " "), item.author or "")
  item.opts.text = { "issue_text", "title" }
  item.text = Snacks.picker.util.text(raw, item.opts.text)
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
  Snacks.picker.gh_issue(vim.tbl_extend("force", {
    repo = M.repo(),
    live = false,
    limit = 200,
    transform = searchable,
    confirm = confirm,
  }, opts or {}))
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
--- open issues; one with none open lists its closed ones too.
function M.by_milestone()
  local repo = M.repo()
  local cmd = {
    "gh",
    "api",
    ("repos/%s/milestones?state=open&per_page=100"):format(repo or "{owner}/{repo}"),
    "--jq",
    'sort_by(-.open_issues)[] | "\\(.title)\t\\(.open_issues)"',
  }
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return Snacks.notify.error(vim.trim(res.stderr or "gh api milestones failed"))
      end
      local milestones = vim.split(vim.trim(res.stdout), "\n", { trimempty = true })
      vim.ui.select(milestones, {
        prompt = "Issues in milestone",
        format_item = function(line)
          return (line:gsub("\t(%d+)$", "  %1 open"))
        end,
      }, function(line)
        local title, open = (line or ""):match("^(.-)\t(%d+)$")
        if title then
          M.pick({
            milestone = title,
            state = open == "0" and "all" or "open",
            title = "  Issues · " .. title,
          })
        end
      end)
    end)
  end)
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
