-- LazyVim's <leader>ql loads the newest session anywhere, so nvim opened in one
-- project came up in another. Here it loads this directory's session, as qs does.
-- Nvim started under /tmp (Claude's Ctrl-G prompt edits) saves no session, so
-- those blank buffers never become anyone's session.
return {
  "folke/persistence.nvim",
  config = function(_, opts)
    local persistence = require("persistence")
    persistence.setup(opts)
    if vim.fn.getcwd():find("^/tmp/") then
      persistence.stop()
    end
  end,
  keys = {
    {
      "<leader>ql",
      function()
        require("persistence").load()
      end,
      desc = "Restore Session (cwd)",
    },
  },
}
