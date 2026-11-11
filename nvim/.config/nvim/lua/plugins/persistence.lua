-- `nvim` with no file arguments restores the cwd's session; autocmds.lua loads after VimEnter, so this sits in init.
return {
  "folke/persistence.nvim",
  init = function()
    local group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true })
    vim.api.nvim_create_autocmd("StdinReadPre", {
      group = group,
      callback = function()
        vim.g.started_with_stdin = true
      end,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true,
      callback = function()
        if vim.fn.argc(-1) == 0 and not vim.g.started_with_stdin then
          require("persistence").load()
        end
      end,
    })
  end,
}
