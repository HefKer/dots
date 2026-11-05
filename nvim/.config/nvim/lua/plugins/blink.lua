return {
  "saghen/blink.cmp",
  opts = {
    -- <C-k> moves to the split or herdr pane above, even in insert mode
    -- (config/keymaps.lua); blink's buffer-local signature toggle would win.
    keymap = { ["<C-k>"] = false },
    sources = {
      default = { "claude_prompt" },
      providers = {
        claude_prompt = {
          name = "Claude",
          module = "config.prompt_source",
          enabled = function()
            return vim.b.claude_prompt == true
          end,
          fallbacks = { "snippets", "buffer", "path" },
        },
      },
    },
  },
}
