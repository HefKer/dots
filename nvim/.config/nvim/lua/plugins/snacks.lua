return {
  "folke/snacks.nvim",
  opts = {
    -- Opens image files as images, and shows a markdown image link's image in
    -- a float while the cursor is on it. Not inline: snacks sends PNGs as-is
    -- and WezTerm downscales them roughly, so the 80-column inline default
    -- blurs screenshots. The float grows to the window, close to native size.
    image = {
      enabled = true,
      doc = { inline = false, float = true, max_width = 200, max_height = 60 },
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
