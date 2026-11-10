-- Pipe tables in markdown buffers, drawn in place as box grids whose cells wrap to fit
-- the window (config.prompt_table). The source rows are hidden with conceal_lines and
-- the grid sits in virtual lines above them, so the buffer text is untouched. This
-- replaces render-markdown's tables, which pad every row to its widest cell and break
-- mid-row under soft wrap. Hidden rows follow 'conceallevel', so they disappear with
-- render-markdown's other conceals when it is toggled off. The cursor can't be seen
-- on a hidden row, so the grid row of the cursor's source line is highlighted instead.
local M = {}

local tables = require("config.prompt_table")
local ns = vim.api.nvim_create_namespace("markdown_tables")
-- buf -> { tick, width, drawn }, so cursor moves don't redraw the tables
local cache = {}

-- A drawn line and its { row, start, end, hl } marks -> virt_line chunks, the marks
-- stacked in the order given.
local function chunks(text, marks)
  local cuts = { [0] = true, [#text] = true }
  for _, m in ipairs(marks) do
    cuts[m[2]], cuts[m[3]] = true, true
  end
  local pos = vim.tbl_keys(cuts)
  table.sort(pos)
  local out = {}
  for i = 1, #pos - 1 do
    local s, e, hl = pos[i], pos[i + 1], {}
    for _, m in ipairs(marks) do
      if m[2] <= s and m[3] >= e then
        table.insert(hl, m[4])
      end
    end
    table.insert(out, { text:sub(s + 1, e), hl })
  end
  return out
end

local function shown(buf)
  local ok, state = pcall(require, "render-markdown.state")
  return not ok or state.get(buf).enabled
end

---@param buf integer
function M.draw(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local win = vim.fn.bufwinid(buf)
  if win == -1 or vim.wo[win].diff or not shown(buf) then
    return
  end
  local info = vim.fn.getwininfo(win)[1]
  -- one column short, so a full-width box row doesn't hit the edge
  local width, tick = info.width - info.textoff - 1, vim.b[buf].changedtick
  local c = cache[buf]
  if not c or c.tick ~= tick or c.width ~= width then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    c = { tick = tick, width = width, drawn = tables.render(lines, width), lines = lines }
    cache[buf] = c
  end
  local drawn, lines = c.drawn, c.lines
  if not next(drawn.source) then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(win)[1]

  local by_row = {}
  for _, m in ipairs(drawn.marks) do
    by_row[m[1]] = by_row[m[1]] or {}
    table.insert(by_row[m[1]], m)
  end
  -- drawn.source maps each grid row to its table's { first, last } source lines
  local grids, order = {}, {}
  for row, text in ipairs(drawn.lines) do
    local src = drawn.source[row]
    if src then
      if not grids[src[1]] then
        grids[src[1]] = { last = src[2], lines = {} }
        table.insert(order, src[1])
      end
      local line = chunks(text, by_row[row - 1] or {})
      if drawn.line[row] == cursor then
        for _, chunk in ipairs(line) do
          table.insert(chunk[2], "CursorLine")
        end
      end
      table.insert(grids[src[1]].lines, line)
    end
  end
  for _, first in ipairs(order) do
    local g = grids[first]
    vim.api.nvim_buf_set_extmark(buf, ns, first - 1, 0, {
      end_row = g.last - 1,
      end_col = #lines[g.last],
      conceal_lines = "",
    })
    -- virt_lines on a concealed line aren't drawn, so hang them off a neighbour:
    -- above the next line by preference, since nvim scrolls through lines above a
    -- line partially (like diff filler) but not through lines below one, which
    -- pushes the cursor around near a grid taller than the window
    if g.last < #lines then
      vim.api.nvim_buf_set_extmark(buf, ns, g.last, 0, { virt_lines = g.lines, virt_lines_above = true })
    elseif first > 1 then
      vim.api.nvim_buf_set_extmark(buf, ns, first - 2, 0, { virt_lines = g.lines })
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("markdown_tables", { clear = true })
  local pending = {}
  local function schedule(buf)
    if pending[buf] then
      return
    end
    pending[buf] = true
    vim.defer_fn(function()
      pending[buf] = nil
      M.draw(buf)
    end, 50)
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(ev)
      vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
        group = group,
        buffer = ev.buf,
        callback = function()
          schedule(ev.buf)
        end,
      })
      local last
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        buffer = ev.buf,
        callback = function()
          local row = vim.api.nvim_win_get_cursor(0)[1]
          if row ~= last then
            last = row
            M.draw(ev.buf)
          end
        end,
      })
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = ev.buf,
        callback = function()
          cache[ev.buf] = nil
        end,
      })
      schedule(ev.buf)
    end,
  })
  -- resizes, and render-markdown toggling (it sets 'conceallevel' and 'diff')
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      for _, win in ipairs(vim.v.event.windows) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "markdown" then
          schedule(buf)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = { "conceallevel", "diff" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].filetype == "markdown" then
        schedule(buf)
      end
    end,
  })
end

return M
