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
        -- insert-mode <C-k> moves to the split or herdr pane above, also in keymaps.lua
        ["*"] = { keys = { { "<leader>cR", false }, { "<c-k>", false, mode = "i" } } },
        bashls = {},
        yamlls = {},
        pyright = {},
        jsonls = {},
        nil_ls = { mason = false }, -- nil_ls provided by nix
        taplo = { mason = false }, -- provided by nix
      },
    },
  },
}
