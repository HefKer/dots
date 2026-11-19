return {
  "folke/snacks.nvim",
  keys = {
    -- One note per project and filetype, across branches and worktrees (config.scratch)
    {
      "<leader>.",
      function()
        require("config.scratch").open()
      end,
      desc = "Toggle Scratch Buffer",
    },
    -- The issue this work belongs to, and the tracker's open issues, in place
    -- of LazyVim's lists of the git remote's repo (config.issue)
    {
      "<leader>gi",
      function()
        require("config.issue").open()
      end,
      desc = "GitHub Issue (this work)",
    },
    {
      "<leader>gI",
      function()
        require("config.issue").pick()
      end,
      desc = "GitHub Issues (open)",
    },
    -- Inline images are capped at 80 columns, and WezTerm blurs a screenshot
    -- shrunk that far. This opens the image file in a near-fullscreen float,
    -- where snacks renders it at the window's size.
    {
      "<leader>ci",
      function()
        Snacks.image.doc.at_cursor(function(src)
          if not src then
            return Snacks.notify.warn("No image under the cursor")
          end
          Snacks.win({ file = src, width = 0.9, height = 0.9, border = "rounded", keys = { q = "close" } })
        end)
      end,
      desc = "Image Under Cursor (Float)",
    },
  },
  opts = {
    -- Renders markdown images inline and opens image files as images.
    image = {
      enabled = true,
      -- Obsidian embeds an attachment by name alone (![[name.png]]), so also
      -- look in the vault's attachment folder; nil falls back to snacks' own lookup.
      resolve = function(file, src)
        local dir = require("config.obsidian").attachment_dir(file)
        local path = dir and dir .. "/" .. src
        return path and vim.uv.fs_stat(path) and path or nil
      end,
    },
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
        explorer = {
          actions = {
            -- explorer_rename, prompting for the name only (config.rename)
            explorer_rename_name = function(picker, item)
              if not item then
                return
              end
              require("config.rename").rename(item.file, function(new, old)
                local Tree = require("snacks.explorer.tree")
                Tree:refresh(vim.fs.dirname(old))
                Tree:refresh(vim.fs.dirname(new))
                require("snacks.explorer.actions").update(picker, { target = new })
              end)
            end,
          },
          win = { list = { keys = { ["r"] = "explorer_rename_name" } } },
        },
      },
    },
  },
}
