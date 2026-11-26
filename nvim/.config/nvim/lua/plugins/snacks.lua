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
    -- The issue this work belongs to, and the tracker's issues (open, all, by
    -- label or milestone), in place of LazyVim's lists of the git remote's
    -- repo (config.issue)
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
    {
      "<leader>gt",
      function()
        require("config.issue").by_label()
      end,
      desc = "GitHub Issues by Label",
    },
    {
      "<leader>ga",
      function()
        require("config.issue").all()
      end,
      desc = "GitHub Issues (all, closed too)",
    },
    {
      "<leader>gm",
      function()
        require("config.issue").by_milestone()
      end,
      desc = "GitHub Issues by Milestone",
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
    -- In an issue buffer, Enter or gf on a #n in the Blocked by, Blocking,
    -- Parent or Sub-issues rows opens that issue; elsewhere Enter keeps
    -- snacks' actions menu and gf its usual file jump (config.issue).
    gh = {
      keys = {
        select = {
          "<cr>",
          function(item)
            require("config.issue").follow(function(it)
              require("snacks.gh.actions").actions.gh_actions.action(it, { items = { it } })
            end)(item)
          end,
          desc = "Open Related Issue or Select Action",
        },
        issue_ref = {
          "gf",
          function(item)
            require("config.issue").follow(function()
              pcall(vim.cmd, "normal! gf")
            end)(item)
          end,
          desc = "Open Related Issue or File",
        },
      },
    },
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
