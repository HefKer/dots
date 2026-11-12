-- Plugins for learning better Vim habits.
return {
  -- Hints a better command after inefficient keys (`jjjj` -> `5j`, `d$` -> `D`).
  {
    "m4xshen/hardtime.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = { restriction_mode = "hint" },
  },
  -- Highlights the characters `f`/`t` reach in one press.
  {
    "jinh0/eyeliner.nvim",
    event = "VeryLazy",
    opts = { highlight_on_key = false, dim = true },
  },
}
