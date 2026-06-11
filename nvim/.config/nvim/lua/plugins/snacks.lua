return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      hidden = true,
      ignored = true,

      exclude = {
        ".git",
        "node_modules",
        "dist",
        "build",
        ".venv",
      },

      sources = {
        files = {
          hidden = true,
          ignored = true,
        },
        grep = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
