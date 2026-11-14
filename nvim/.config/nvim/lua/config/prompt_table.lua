-- Pipe tables in the prompt pane's reply viewer, redrawn as plain-text box grids whose
-- cells wrap to fit the window. render-markdown pads each row to its widest cell, so
-- a table wider than the window breaks mid-row under soft wrap, and its own cell
-- wrapping shows the cursor row as raw markdown. Markers are stripped rather than
-- concealed, since nvim wraps on the raw width, and code spans, header and borders
-- are coloured with extmarks instead.
--
-- Rows drawn into a markdown buffer (the viewer) are still parsed as markdown, so the
-- inline parser would pair a stray _ or * across rows and conceal it, shifting the
-- borders. With `escape`, each such marker is drawn backslash-escaped: the parser
-- conceals only the backslash, always, and the grid is narrowed until its raw width,
-- which is what nvim wraps on, still fits.
local M = {}

local dw = vim.fn.strdisplaywidth

-- ASCII punctuation the inline parser can conceal or pair: escapes, emphasis,
-- strikethrough, links, images, autolinks and HTML, entities, latex.
local function escape(text)
  return (text:gsub("[\\`*_%[%]<>&!~$]", "\\%0"))
end

-- Cell text -> segments { text, code, bold }, cut at ` and ** (not inside code).
local function segments(text)
  local out, cur, code, bold, i = {}, "", false, false, 1
  local function flush()
    if cur ~= "" then
      table.insert(out, { text = cur, code = code, bold = bold })
    end
    cur = ""
  end
  while i <= #text do
    local c = text:sub(i, i)
    if c == "`" then
      flush()
      code = not code
    elseif not code and text:sub(i, i + 1) == "**" then
      flush()
      bold = not bold
      i = i + 1
    else
      cur = cur .. c
    end
    i = i + 1
  end
  flush()
  return out
end

-- Segments -> units, each the run of segments between whitespace, so `config.kdl`;
-- wraps as one word with no space before the ;
local function units(text)
  local out, glue = {}, false
  for _, seg in ipairs(segments(text)) do
    local first = true
    for lead, word in seg.text:gmatch("(%s*)(%S+)") do
      local piece = { text = word, code = seg.code, bold = seg.bold }
      if first and lead == "" and glue and #out > 0 then
        table.insert(out[#out], piece)
      else
        table.insert(out, { piece })
      end
      first = false
    end
    glue = not seg.text:match("%s$")
  end
  return out
end

local function unit_width(unit)
  local n = 0
  for _, piece in ipairs(unit) do
    n = n + dw(piece.text)
  end
  return n
end

-- A unit wider than the column, cut into column-wide units.
local function cut(unit, w)
  local out, cur, len = {}, {}, 0
  for _, piece in ipairs(unit) do
    local text = piece.text
    while text ~= "" do
      local fit = 0
      while fit < vim.fn.strchars(text) and len + dw(vim.fn.strcharpart(text, 0, fit + 1)) <= w do
        fit = fit + 1
      end
      if fit == 0 then
        table.insert(out, cur)
        cur, len = {}, 0
        fit = 1
      end
      local head = vim.fn.strcharpart(text, 0, fit)
      table.insert(cur, { text = head, code = piece.code, bold = piece.bold })
      len = len + dw(head)
      text = vim.fn.strcharpart(text, fit)
    end
  end
  table.insert(out, cur)
  return out
end

-- Cell text -> lines, each a list of units.
local function wrap(text, w)
  local out, cur, len = {}, {}, 0
  local function push(unit, uw)
    local add = (len > 0 and 1 or 0) + uw
    if len > 0 and len + add > w then
      table.insert(out, cur)
      cur, len, add = {}, 0, uw
    end
    table.insert(cur, unit)
    len = len + add
  end
  for _, unit in ipairs(units(text)) do
    local uw = unit_width(unit)
    if uw > w then
      for _, part in ipairs(cut(unit, w)) do
        push(part, unit_width(part))
      end
    else
      push(unit, uw)
    end
  end
  table.insert(out, cur)
  return out
end

local function split_row(line)
  local cells = {}
  -- links show their text: [text](target) -> text
  line = line:gsub("%[([^%]]*)%]%b()", "%1")
  local body = line:gsub("\\|", "\0"):gsub("^%s*|", ""):gsub("|%s*$", "")
  for cell in (body .. "|"):gmatch("(.-)|") do
    table.insert(cells, (vim.trim(cell):gsub("%z", "|")))
  end
  return cells
end

-- Narrow columns keep their natural width; the rest share what's left evenly.
local function fit(natural, avail)
  local widths, left, order = {}, avail, {}
  for i in ipairs(natural) do
    table.insert(order, i)
  end
  table.sort(order, function(a, b)
    return natural[a] < natural[b]
  end)
  for n, i in ipairs(order) do
    widths[i] = math.max(math.min(natural[i], math.floor(left / (#order - n + 1))), 4)
    left = left - widths[i]
  end
  return widths
end

---@param rows string[][] header first
---@param width integer columns available
---@param emit fun(line: string, marks: table[], ri?: integer) ri: the row a content line belongs to
---@param esc? boolean backslash-escape markdown markers in cell text
local function draw(rows, width, emit, esc)
  local k = 0
  for _, r in ipairs(rows) do
    k = math.max(k, #r)
  end
  local natural = {}
  for c = 1, k do
    natural[c] = 1
    for _, r in ipairs(rows) do
      natural[c] = math.max(natural[c], unit_width(segments(r[c] or "")))
    end
  end
  local w = fit(natural, width - (3 * k + 1))
  local function rule(l, m, r)
    local parts = {}
    for c = 1, k do
      table.insert(parts, ("─"):rep(w[c] + 2))
    end
    emit(l .. table.concat(parts, m) .. r, {})
  end
  rule("┌", "┬", "┐")
  for ri, r in ipairs(rows) do
    local cells, h = {}, 1
    for c = 1, k do
      cells[c] = wrap(r[c] or "", w[c])
      h = math.max(h, #cells[c])
    end
    for li = 1, h do
      local line, marks = "│", {}
      for c = 1, k do
        line = line .. " "
        local used = 0
        for ui, unit in ipairs(cells[c][li] or {}) do
          if ui > 1 then
            line, used = line .. " ", used + 1
          end
          for _, piece in ipairs(unit) do
            local s = #line
            line, used = line .. (esc and escape(piece.text) or piece.text), used + dw(piece.text)
            local e = #line
            if piece.code then
              table.insert(marks, { s, e, "RenderMarkdownCodeInline" })
              table.insert(marks, { s, e, "@markup.raw.markdown_inline" })
            elseif ri == 1 then
              table.insert(marks, { s, e, "RenderMarkdownTableHead" })
            else
              table.insert(marks, { s, e, "Normal" })
            end
            if piece.bold then
              table.insert(marks, { s, e, "@markup.strong" })
            end
          end
        end
        line = line .. (" "):rep(w[c] - used) .. " │"
      end
      emit(line, marks, ri)
    end
    if ri == 1 then
      rule("├", "┼", "┤")
    end
  end
  rule("└", "┴", "┘")
end

---@class prompt_table.Rendered
---@field lines string[] what the viewer shows
---@field marks table[] { row, start_col, end_col, hl_group }, 0-based rows
---@field source table<integer, integer[]> viewer row (1-based) -> { first, last } source lines of its table
---@field line table<integer, integer> viewer row (1-based) -> source line of its table row; rules have none

-- Redraws every pipe table outside code fences in `lines` as a box grid `width` wide.
---@param lines string[]
---@param width integer
---@param opts? { escape?: boolean } escape: the grid goes into a markdown buffer (see top)
---@return prompt_table.Rendered
function M.render(lines, width, opts)
  local esc = opts and opts.escape
  local out = { lines = {}, marks = {}, source = {}, line = {} }
  local i, fence = 1, nil
  while i <= #lines do
    local line = lines[i]
    local f = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
    if f and (not fence or f:sub(1, 1) == fence:sub(1, 1) and #f >= #fence) then
      fence = not fence and f or nil
    end
    if not fence and line:match("^%s*|") and (lines[i + 1] or ""):match("^%s*|[%s:|-]+$") then
      local first, rows = i, { split_row(line) }
      i = i + 2
      while i <= #lines and lines[i]:match("^%s*|") do
        table.insert(rows, split_row(lines[i]))
        i = i + 1
      end
      -- escapes are hidden but count toward wrapping: narrow until the widest raw line fits
      local drawn, w = {}, width
      for _ = 1, 5 do
        drawn = {}
        draw(rows, w, function(text, marks, ri)
          table.insert(drawn, { text, marks, ri })
        end, esc)
        local over = 0
        for _, d in ipairs(drawn) do
          over = math.max(over, dw(d[1]) - width)
        end
        if over <= 0 then
          break
        end
        w = w - over
      end
      for _, d in ipairs(drawn) do
        local text, marks, ri = d[1], d[2], d[3]
        table.insert(out.lines, text)
        local row = #out.lines
        out.source[row] = { first, i - 1 }
        -- the header is the first source line; body rows follow the delimiter line
        out.line[row] = ri and (ri == 1 and first or first + ri) or nil
        -- borders: the whole line, under the text marks
        table.insert(out.marks, { row - 1, 0, #text, "RenderMarkdownTableRow", 100 })
        for _, m in ipairs(marks) do
          table.insert(out.marks, { row - 1, m[1], m[2], m[3], 110 })
        end
      end
    else
      table.insert(out.lines, line)
      i = i + 1
    end
  end
  return out
end

return M
