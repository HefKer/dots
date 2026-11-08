-- Statusline badge when <leader>. (Snacks.scratch) has content here. Snacks keys
-- scratch files by cwd, git branch and filetype, so this counts the non-empty
-- ones whose .meta matches the current cwd and branch. It reads the .meta files
-- directly: Snacks.scratch.get() would write a new one as a side effect.
local count = 0

local function refresh()
  local root = vim.fn.stdpath("data") .. "/scratch"
  local cwd = vim.fs.normalize(assert(vim.uv.cwd()))
  local branch
  if vim.uv.fs_stat(".git") then
    local out = vim.trim(vim.fn.systemlist("git branch --show-current")[1] or "")
    branch = vim.v.shell_error == 0 and out ~= "" and out or nil
  end
  local n = 0
  for name, t in vim.fs.dir(root) do
    if t == "file" and name:sub(-5) == ".meta" then
      local file = root .. "/" .. name:sub(1, -6)
      local stat = vim.uv.fs_stat(file)
      if stat and stat.size > 0 then
        local ok, meta = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. "/" .. name), "\n"))
        if ok and type(meta) == "table" and meta.cwd == cwd and meta.branch == branch then
          -- a file of only whitespace counts as empty
          if table.concat(vim.fn.readfile(file), ""):match("%S") then
            n = n + 1
          end
        end
      end
    end
  end
  count = n
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local root = vim.fn.stdpath("data") .. "/scratch/"
    vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "FocusGained", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("scratch_indicator", { clear = true }),
      callback = function(ev)
        if ev.event ~= "BufWritePost" or ev.match:sub(1, #root) == root then
          refresh()
        end
      end,
    })
    refresh()
    table.insert(opts.sections.lualine_x, 1, {
      function()
        return "󰎚 " .. count
      end,
      cond = function()
        return count > 0
      end,
      color = function()
        return { fg = Snacks.util.color("DiagnosticWarn") }
      end,
      on_click = function()
        Snacks.scratch()
      end,
    })
  end,
}
