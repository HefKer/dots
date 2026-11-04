return {
  "folke/snacks.nvim",
  keys = {
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
    image = { enabled = true },
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
