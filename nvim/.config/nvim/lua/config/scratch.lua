-- <leader>. (Snacks.scratch) keyed by project instead of directory and branch,
-- so a note written on one branch or worktree is there from all the others.
-- The project is the repo's common git dir, which every worktree of it shares;
-- outside a repo it is the working directory, which keys a note the way Snacks
-- did, so those notes keep opening. Notes are written in Snacks' own format
-- (a hashed file plus its .meta), so <leader>S still lists them all, the old
-- per-branch ones included.
local M = {}

M.root = vim.fn.stdpath("data") .. "/scratch"

--- The directory a note is keyed by, and shown under in <leader>S.
---@return string
function M.project()
  local cwd = vim.fs.normalize(assert(vim.uv.cwd()))
  local out = vim.fn.systemlist({ "git", "rev-parse", "--path-format=absolute", "--git-common-dir" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return cwd
  end
  local dir = vim.fs.normalize(out[1])
  -- A hidden git dir (.git, or this flake's .bare) sits inside its project; a
  -- bare repo or a submodule's dir under .git/modules is the project itself.
  return vim.fs.basename(dir):sub(1, 1) == "." and vim.fs.dirname(dir) or dir
end

--- Whether a note's .meta is keyed by this project, as open() writes it: a
--- note Snacks keyed by branch has a branch in its .meta.
---@param meta table
---@param project string
function M.owns(meta, project)
  return meta.cwd == project and meta.branch == nil
end

--- Open (or close, if shown) the current project's note for this filetype.
function M.open()
  local ft = vim.bo.buftype == "" and vim.bo.filetype ~= "" and vim.bo.filetype or "markdown"
  local icon, icon_hl = Snacks.util.icon(ft, "filetype")
  local meta = { name = "Scratch", ft = ft, count = vim.v.count1, cwd = M.project(), icon = icon, icon_hl = icon_hl }
  -- Snacks.scratch._write_meta's key without the branch, so a note outside a
  -- repo hashes to the file Snacks gave it
  local hash = vim.fn.sha256(table.concat({ meta.name, tostring(meta.count), meta.cwd }, "|")):sub(1, 8)
  local file = ("%s/%s.%s"):format(M.root, hash, ft)
  vim.fn.mkdir(M.root, "p")
  -- Snacks writes no .meta for a note opened by file, and lists only those with one
  vim.fn.writefile({ vim.json.encode(meta) }, file .. ".meta")
  Snacks.scratch.open({ file = file, name = meta.name })
end

return M
