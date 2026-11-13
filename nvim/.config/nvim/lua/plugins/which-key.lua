return {
  "folke/which-key.nvim",
  -- Names <leader>a for the Claude prompt pane's binds and <leader>ap, and <leader>h. LazyVim
  -- ships this group only inside its AI extras, none of which is enabled.
  -- A function, since a list in opts would replace LazyVim's spec, not extend it.
  opts = function(_, opts)
    opts.spec = opts.spec or {}
    table.insert(opts.spec, { "<leader>a", group = "ai", mode = { "n", "x" } })
    -- Habit capture and the Vim inbox (config/habit_capture.lua).
    table.insert(opts.spec, { "<leader>h", group = "habits" })
  end,
}
