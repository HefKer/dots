return {
  {
    "mason-org/mason.nvim",
    opts = {
      PATH = "skip",
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_installation = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
        yamlls = {},
        pyright = {},
        jsonls = {},
      },
    },
  },
}
