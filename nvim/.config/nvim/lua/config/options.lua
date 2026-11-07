-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Heavy lines for split borders, so a split reads as a border and not a faint rule.
vim.opt.fillchars:append({
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vert = "┃",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
})

-- Rounded border on LSP hover, signature help and diagnostic floats. Their
-- background is cleared for WezTerm's opacity (plugins/colorscheme.lua), so
-- without one a float reads as more lines of code.
vim.o.winborder = "rounded" -- none|single|double|rounded|solid|shadow|bold

-- Trailing spaces and non-breaking spaces as glyphs no code uses: the default
-- "-" and "+" read as operators ("return 1--"). tab is nvim's default.
vim.opt.listchars = { tab = "> ", trail = "·", nbsp = "␣" } -- trail: -|·|•  nbsp: +|␣|⍽
