-- Plugins for learning better Vim habits.
return {
  -- Hints a better command after inefficient keys (`jjjj` -> `5j`, `d$` -> `D`).
  {
    "m4xshen/hardtime.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      restriction_mode = "hint",
      -- Keep the arrow keys; an empty mode list unblocks a key.
      disabled_keys = { ["<Up>"] = {}, ["<Down>"] = {}, ["<Left>"] = {}, ["<Right>"] = {} },
    },
  },
  -- On `f`/`t`/`F`/`T`, highlights the characters reachable in one press.
  {
    "jinh0/eyeliner.nvim",
    event = "VeryLazy",
    opts = { highlight_on_key = true, dim = true },
  },
  -- eyeliner maps f/t/F/T per buffer, so flash's char mode would be shadowed anyway.
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } },
  },
}
