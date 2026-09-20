-- DMS's matugen template rewrites colors/dms.lua on every theme change, so any
-- fix has to live outside that file. These groups come out of the green
-- harmonization too dim against the everforest background (#333c43), so we
-- reassert everforest's own values after the colorscheme loads.
local overrides = {
  -- snacks explorer/picker link ignored + hidden paths and ignored git status
  -- to NonText; the generated #424d50 is nearly invisible on the background.
  NonText = { fg = "#859289" },
  -- generated Visual is #3a4248 -- indistinguishable from CursorLine.
  Visual = { bg = "#493b40" },
}

local function apply_overrides()
  for group, opts in pairs(overrides) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return {
  -- Supplies the base46 theme tables that colors/dms.lua -- written by DMS's
  -- matugen template -- loads, harmonizes and applies.
  {
    "AvengeMedia/base46",
    lazy = false,
    priority = 1000,
    init = function()
      -- registered from init so it is in place before LazyVim sets the
      -- colorscheme, and re-runs when the theme watcher reloads it.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("dms_theme_overrides", { clear = true }),
        pattern = "dms",
        callback = apply_overrides,
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "dms" },
  },
}
