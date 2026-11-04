return {
  -- v3 moved every multiplexer into its own plugin and dropped herdr from core,
  -- so herdr comes from a community backend. Its herdr half (the plugin that
  -- forwards ctrl+hjkl into nvim) is packaged in the nixos flake.
  "smart-splits-nvim/smart-splits.nvim",
  version = "^3.0.0",
  lazy = false,
  dependencies = {
    {
      "adriankarlen/smart-splits-backend-herdr",
      main = "smart-splits-backend-herdr",
      -- The herdr half ignores zoom and moves focus to the hidden neighbour, which
      -- herdr then shows zoomed; match it so ctrl+hjkl acts the same from nvim.
      opts = { disable_nav_when_zoomed = false },
    },
  },
  opts = {
    -- Don't wrap around at the outermost split; hand off to the multiplexer instead.
    move = { at_edge = "stop" },
    -- The backend only reports itself usable inside herdr; elsewhere plain splits are expected.
    mux = { backend = "smart-splits-backend-herdr", warn_if_unusable = false },
  },
}
