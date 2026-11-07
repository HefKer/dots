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
      -- bullets' renumbering always counts from 1, so a list starting at 12
      -- became 1, 2, ... Renumber below instead, counting from the first item.
      vim.g.bullets_renumber_on_change = 0

      -- Renumber the numbered items at the cursor line's indent, from the list's
      -- first number. Nested and wrapped lines (deeper indent) are passed over;
      -- a blank line, a shallower one, or a non-numbered one at this indent ends
      -- the list.
      local function renumber()
        local row = vim.fn.line(".")
        local indent = vim.fn.indent(row)
        local function item(lnum)
          local line = vim.fn.getline(lnum)
          if line:match("^%s*$") or vim.fn.indent(lnum) < indent then
            return false
          end
          if vim.fn.indent(lnum) > indent then
            return nil -- nested or wrapped: skip, keep going
          end
          local lead, num, rest = line:match("^(%s*)(%d+)([.)]%s.*)$")
          return num and { lead = lead, num = tonumber(num), rest = rest } or false
        end
        if not item(row) then
          return
        end
        local first, last = row, row
        for lnum = row - 1, 1, -1 do
          local it = item(lnum)
          if it == false then
            break
          elseif it then
            first = lnum
          end
        end
        for lnum = row + 1, vim.fn.line("$") do
          local it = item(lnum)
          if it == false then
            break
          elseif it then
            last = lnum
          end
        end
        local n = item(first).num
        for lnum = first, last do
          local it = item(lnum)
          if it then
            local new = it.lead .. n .. it.rest
            if new ~= vim.fn.getline(lnum) then
              vim.fn.setline(lnum, new)
            end
            n = n + 1
          end
        end
        -- bullets left the cursor at the end of the new item; keep it there if
        -- the number grew (9 -> 10).
        vim.api.nvim_win_set_cursor(0, { row, #vim.api.nvim_get_current_line() })
      end

      -- Off a list item, bullets' own <CR> queues the newline behind any keys
      -- already typed, so a macro or . repeat puts it after the text that
      -- followed. Hand it only an item with the cursor at the end of the line.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("bullets_cr", { clear = true }),
        pattern = { "markdown", "text", "gitcommit" },
        callback = function(ev)
          vim.keymap.set("i", "<Plug>(renumber-list)", renumber, { buffer = ev.buf })
          vim.keymap.set("i", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            local item = line:match("^%s*[-*+]%s") or line:match("^%s*%d+[.)]%s") or line:match("^%s*%a[.)]%s")
            return (item and vim.fn.col(".") > #line) and "<Plug>(bullets-newline)<Plug>(renumber-list)" or "<CR>"
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
