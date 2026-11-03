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
