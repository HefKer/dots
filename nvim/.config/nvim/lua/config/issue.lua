-- <leader>gi opens the issue this work belongs to as a buffer (Snacks.gh):
-- body and every comment, with a to comment, c to close, <CR> for labels and
-- the rest. LazyVim's own <leader>gi lists the issues of the git remote's
-- repo, which is empty where the tracker is a separate repo, and asks GitHub
-- again on every keystroke.
-- The tracker is the backlog project whose name is a directory on the cwd's
-- path (~/nixos/main -> nixos); the number is the one in the label of the
-- agent pane sharing this herdr tab ("#155 ..."), else the newest one the
-- branch's commits reference (owner/repo#155). With no number, the picker.
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

--- The tracker's open issues, fetched once and filtered locally.
function M.pick()
  local repo = M.repo()
  -- Outside a backlog project, the remote's repo, as LazyVim's bind did
  Snacks.picker.gh_issue({ repo = repo, live = false })
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
