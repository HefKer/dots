return {
  "folke/which-key.nvim",
  -- Names <leader>a for the Claude prompt pane's binds and <leader>ap. LazyVim
  -- ships this group only inside its AI extras, none of which is enabled.
  -- A function, since a list in opts would replace LazyVim's spec, not extend it.
  opts = function(_, opts)
    opts.spec = opts.spec or {}
    table.insert(opts.spec, { "<leader>a", group = "ai", mode = { "n", "x" } })
  end,
}
