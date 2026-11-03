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
        -- <leader>cR is set for every buffer in keymaps.lua, not only under an LSP with file renames
        ["*"] = { keys = { { "<leader>cR", false } } },
        bashls = {},
        yamlls = {},
        pyright = {},
        jsonls = {},
        nil_ls = { mason = false }, -- nil_ls provided by nix
      },
    },
  },
}
