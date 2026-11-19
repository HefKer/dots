-- Statusline badge when <leader>. has content here: counts the non-empty notes
-- keyed by this project (config.scratch), whatever the branch or worktree. It
-- reads the .meta files directly: Snacks.scratch.get() would write a new one as
-- a side effect.
local scratch = require("config.scratch")
local count = 0

local function refresh()
  local root = scratch.root
  local project = scratch.project()
  local n = 0
  for name, t in vim.fs.dir(root) do
    if t == "file" and name:sub(-5) == ".meta" then
      local file = root .. "/" .. name:sub(1, -6)
      local stat = vim.uv.fs_stat(file)
      if stat and stat.size > 0 then
        local ok, meta = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. "/" .. name), "\n"))
        if ok and type(meta) == "table" and scratch.owns(meta, project) then
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
    local root = scratch.root .. "/"
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
        scratch.open()
      end,
    })
  end,
}
