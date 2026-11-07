return {
  "folke/noice.nvim",
  opts = {
    -- noice draws hover (K) and signature help itself, so winborder in
    -- config/options.lua doesn't reach them; this gives them the same rounded border.
    presets = { lsp_doc_border = true },
  },
}
