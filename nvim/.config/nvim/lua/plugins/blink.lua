return {
  "saghen/blink.cmp",
  opts = {
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
