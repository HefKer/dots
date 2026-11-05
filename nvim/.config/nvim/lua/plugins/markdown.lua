-- On top of LazyVim's lang.markdown extra: marksman resolves [[wikilinks]] and
-- [text](path.md#heading) links, and markdownlint flags only broken markdown.
local lint_config = vim.fn.stdpath("config") .. "/lint/.markdownlint.jsonc"

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          mason = false, -- provided by nix; Mason's build is dynamically linked and won't run on NixOS
          handlers = {
            -- A vault links to notes that don't exist yet on purpose, so drop
            -- marksman's broken- and ambiguous-link errors inside one.
            ["textDocument/publishDiagnostics"] = function(err, result, ctx)
              local client = vim.lsp.get_client_by_id(ctx.client_id)
              if client and client.root_dir and vim.uv.fs_stat(client.root_dir .. "/.obsidian") then
                result.diagnostics = {}
              end
              vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
            end,
          },
        },
      },
    },
  },
  {
    -- <CR> on a list item starts the next one: 1. -> 2., - [x] -> - [ ];
    -- <CR> on an empty item ends the list.
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },
    init = function()
      vim.g.bullets_set_mappings = 0 -- o and O stay plain new lines
      -- Off a list item, bullets' own <CR> queues the newline behind any keys
      -- already typed, so a macro or . repeat puts it after the text that
      -- followed. Hand it only an item with the cursor at the end of the line.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("bullets_cr", { clear = true }),
        pattern = { "markdown", "text", "gitcommit" },
        callback = function(ev)
          vim.keymap.set("i", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            local item = line:match("^%s*[-*+]%s") or line:match("^%s*%d+[.)]%s") or line:match("^%s*%a[.)]%s")
            return (item and vim.fn.col(".") > #line) and "<Plug>(bullets-newline)" or "<CR>"
          end, { buffer = ev.buf, expr = true, remap = true, desc = "Continue List" })
        end,
      })
    end,
  },
  {
    -- Render in every mode, and show raw markdown only on the line being typed
    -- in insert mode, so moving through a table or entering insert doesn't break
    -- the layout. Anti-conceal is switched off by mode rather than per element:
    -- ignoring just table_border isn't enough, as the cell padding that aligns
    -- the columns is always dropped on the cursor line while it is on.
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      render_modes = true,
      anti_conceal = { disabled_modes = { "n", "c" } },
      -- and keep nvim's own conceal on the cursor line in the same modes
      win_options = { concealcursor = { rendered = "nc" } },
      -- No cell wrapping: it swaps any row whose raw text is wider than the window
      -- for virtual lines over a concealed line, so the cursor row shows raw
      -- markdown even in normal mode, and scrolling past them leaves stale rows
      -- and diff-filler hatching. Wide rows wrap like any other line instead.
      pipe_table = { wrap = false },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", lint_config } },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", lint_config } },
      },
    },
  },
}
