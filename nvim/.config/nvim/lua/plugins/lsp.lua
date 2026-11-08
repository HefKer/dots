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
        -- nixd over nil: it evaluates the flake, so NixOS and home-manager option
        -- names complete with their docs. Provided by nix.
        nil_ls = { enabled = false },
        nixd = {
          mason = false,
          settings = {
            nixd = (function()
              local flake = '(builtins.getFlake "' .. vim.env.HOME .. '/nixos/main")'
              local host = flake .. ".nixosConfigurations." .. vim.fn.hostname()
              return {
                nixpkgs = { expr = "import " .. flake .. ".inputs.nixpkgs { }" },
                options = {
                  nixos = { expr = host .. ".options" },
                  home_manager = { expr = host .. ".options.home-manager.users.type.getSubOptions []" },
                },
              }
            end)(),
          },
        },
        fish_lsp = { mason = false }, -- provided by nix
        taplo = { mason = false }, -- provided by nix
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "fish", "kdl" } },
  },
}
