return {
  -- Supplies the base46 theme tables that colors/dms.lua -- written by DMS's
  -- matugen template -- loads, harmonizes and applies.
  { "AvengeMedia/base46", lazy = false, priority = 1000 },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "dms" },
  },
}
