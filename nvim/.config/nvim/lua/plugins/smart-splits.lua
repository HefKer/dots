return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  -- The backend has to be named before the plugin loads: smart-splits resolves
  -- and caches it on load, so setting it in `opts` lands too late and the
  -- auto-detected one sticks. `vim.g` is upstream's hook for exactly this.
  init = function()
    -- Upstream already auto-detects herdr ahead of wezterm (without that, herdr
    -- panes inherit the outer wezterm's env and drive a socket whose wezterm has
    -- since exited: a ~2.5s stall, then nothing). Point it at our wrapper, which
    -- is that backend with resize amounts converted to the ratios herdr expects.
    if vim.env.HERDR_ENV == "1" then
      vim.g.smart_splits_multiplexer_integration = "herdr_ratio"
    end
  end,
  opts = {
    -- Don't wrap around at the outermost split; hand off to the multiplexer instead.
    at_edge = "stop",
  },
}
