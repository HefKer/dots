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
  -- generated WinSeparator is #3a4248, so a split's border all but vanishes
  -- into the background; everforest's grey0 makes it a visible line.
  WinSeparator = { fg = "#7a8478" },
}

-- Editor groups whose background is cleared so WezTerm's window opacity shows
-- through, as in the rest of the terminal. Floats are cleared too: snacks
-- pickers, which-key and noice link to NormalFloat/FloatBorder, and the
-- completion menus to Pmenu or blink's own groups. Selections, scrollbars and
-- float titles keep theirs. (base46's own transparency option is not used: it
-- re-sets these groups to just { bg = "NONE" }, wiping their text colour.)
local transparent = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "FoldColumn",
  "EndOfBuffer",
  "LineNr",
  "CursorLineNr",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  "BlinkCmpMenu",
  "BlinkCmpDoc",
  "BlinkCmpSignatureHelp",
}

local function apply_overrides()
  for group, opts in pairs(overrides) do
    vim.api.nvim_set_hl(0, group, opts)
  end
  for _, group in ipairs(transparent) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = nil
    vim.api.nvim_set_hl(0, group, hl --[[@as vim.api.keyset.highlight]])
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
