-- Habit capture (GLOSSARY.md): a moment where a better way probably existed, written
-- to the Vim inbox in the vault with the keys pressed, the text before and after,
-- and a note on what was meant, for the /vim-inbox skill to answer with the
-- idiomatic way. hardtime and eyeliner hint live; this keeps what they can't see.
local M = {}

M.inbox = vim.fn.expand("~/obsidian/main/vim-inbox.md")

local size = 30 -- keystrokes kept
local max_lines = 5000 -- a bigger buffer gets no text snapshots, only keys
local context = 2 -- lines around a change
local around = 3 -- lines around the cursor when nothing changed
local most = 40 -- lines in one snapshot

-- Each typed key: { key, mode, buf, cursor, lines }, lines being the buffer as it was
-- before the key ran, shared between keys until the buffer changes.
local ring = {}
local last = {} -- { buf, tick, lines }: the newest copy, reused while the tick holds

-- Where a capture would leak a secret: the note alone goes in.
local function denied(name)
  if name == "" then
    return false
  end
  local path = vim.uv.fs_realpath(name) or name
  if path:match("%.age$") or path:match("%.gpg$") then
    return true
  end
  for _, dir in ipairs({ "/dev/shm/", "/tmp/", vim.env.TMPDIR, vim.env.XDG_RUNTIME_DIR }) do
    dir = dir and vim.fs.normalize(dir):gsub("/?$", "/")
    if dir and dir ~= "/" and (path:sub(1, #dir) == dir or name:sub(1, #dir) == dir) then
      return true
    end
  end
  -- rbw and pass edit in a temp file; this catches one moved out of the dirs above.
  return path:match("/rbw[^/]*$") ~= nil or path:match("/pass%.[^/]+/") ~= nil
end

local function on_key(_, typed)
  if not typed or typed == "" then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local entry = {
    key = vim.fn.keytrans(typed),
    mode = vim.api.nvim_get_mode().mode,
    buf = buf,
    cursor = vim.api.nvim_win_get_cursor(0),
  }
  local tick = vim.b[buf].changedtick
  if last.buf ~= buf or last.tick ~= tick then
    local small = vim.api.nvim_buf_line_count(buf) <= max_lines
    last = { buf = buf, tick = tick, lines = small and vim.api.nvim_buf_get_lines(buf, 0, -1, false) or nil }
  end
  entry.lines = last.lines
  table.insert(ring, entry)
  if #ring > size then
    table.remove(ring, 1)
  end
end

-- The keys typed in this buffer, newest last, without the ones that asked for the
-- capture: from the last `:` when run as a command, else the bind's own keys.
local function window(buf, trigger)
  local keys = {}
  for i = #ring, 1, -1 do
    if ring[i].buf ~= buf then
      break
    end
    table.insert(keys, 1, ring[i])
  end
  if trigger == ":" then
    for i = #keys, 1, -1 do
      if keys[i].key == ":" and not keys[i].mode:match("^c") then
        return vim.list_slice(keys, 1, i - 1)
      end
    end
  elseif trigger then
    local drop = vim.fn.keytrans(vim.keycode(trigger))
    local tail = ""
    for i = #keys, 1, -1 do
      tail = keys[i].key .. tail
      if tail == drop then
        return vim.list_slice(keys, 1, i - 1)
      elseif #tail >= #drop then
        break
      end
    end
  end
  return keys
end

-- Rows first..last (1-based) of lines, widened by pad and cut to `most`.
local function slice(lines, first, last, pad)
  first, last = math.max(1, first - pad), math.min(#lines, last + pad)
  return vim.list_slice(lines, first, math.min(last, first + most - 1)), first
end

-- before/after snapshots: the changed rows with context, or the cursor's surroundings
-- where it started and ended when the keys only moved it.
local function snapshots(keys, buf)
  local before = keys[1].lines
  local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if not before or #after > max_lines then
    return
  end
  local hunks = vim.diff(table.concat(before, "\n") .. "\n", table.concat(after, "\n") .. "\n", {
    result_type = "indices",
  }) --[[@as integer[][] ]]
  if #hunks == 0 then
    local from, to = keys[1].cursor[1], vim.api.nvim_win_get_cursor(0)[1]
    local b, bfirst = slice(before, from, from, around)
    local a, afirst = slice(after, to, to, around)
    return b, a, bfirst, afirst
  end
  local function span(start_at, count_at)
    local first, last = math.huge, 0
    for _, h in ipairs(hunks) do
      local start, count = h[start_at], h[count_at]
      -- A pure insertion or deletion has count 0 and starts on the row before it.
      first = math.min(first, count == 0 and start + 1 or start)
      last = math.max(last, count == 0 and start or start + count - 1)
    end
    return first, math.max(first, last)
  end
  local bf, bl = span(1, 2)
  local af, al = span(3, 4)
  local b, bfirst = slice(before, bf, bl, context)
  local a, afirst = slice(after, af, al, context)
  return b, a, bfirst, afirst
end

-- A code span or fence one backtick longer than any run inside it.
local function ticks(text, least)
  local longest = 0
  for run in text:gmatch("`+") do
    longest = math.max(longest, #run)
  end
  return ("`"):rep(math.max(least, longest + 1))
end

local function block(title, lines, first, ft)
  local fence = ticks(table.concat(lines, "\n"), 3)
  local out = { "", ("**%s** (from line %d)"):format(title, first), "", fence .. ft }
  vim.list_extend(out, lines)
  table.insert(out, fence)
  return out
end

-- The entry for the keys typed so far, as markdown lines, or nil when there are none.
local function entry(buf, trigger)
  local keys = window(buf, trigger)
  local out = { "", "## " .. os.date("%Y-%m-%d %H:%M"), "" }
  local name = vim.api.nvim_buf_get_name(buf)
  if denied(name) then
    return out, true
  end
  if #keys == 0 then
    return out, false
  end
  local typed = table.concat(vim.tbl_map(function(k)
    return k.key
  end, keys))
  local modes = {}
  for _, k in ipairs(keys) do
    local mode = k.mode:sub(1, 1)
    if modes[#modes] ~= mode then
      table.insert(modes, mode)
    end
  end
  local tick = ticks(typed, 1)
  local pad = (typed:match("^`") or typed:match("`$")) and " " or ""
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.list_extend(out, {
    ("- keys: %s%s%s%s%s"):format(tick, pad, typed, pad, tick),
    "- mode: " .. table.concat(modes, " → "),
    "- filetype: " .. (vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "none"),
    "- file: " .. (name ~= "" and vim.fn.fnamemodify(name, ":~") or "[No Name]"),
    ("- cursor: %d:%d → %d:%d"):format(keys[1].cursor[1], keys[1].cursor[2], cursor[1], cursor[2]),
  })
  local before, after, bfirst, afirst = snapshots(keys, buf)
  if before then
    vim.list_extend(out, block("Before", before, bfirst, vim.bo[buf].filetype))
    vim.list_extend(out, block("After", after, afirst, vim.bo[buf].filetype))
  end
  return out, false
end

---@param trigger? string what asked for the capture: ":" for the command, or a bind's lhs
function M.capture(trigger)
  local buf = vim.api.nvim_get_current_buf()
  local lines, private = entry(buf, trigger)
  -- The next capture starts from here, kept or not.
  ring = {}
  vim.ui.input({ prompt = "What were you trying to do? " }, function(note)
    note = note and vim.trim(note)
    if not note or note == "" then
      return
    end
    vim.list_extend(lines, { "", "**Note:** " .. note })
    if vim.fn.filereadable(M.inbox) == 0 then
      table.insert(lines, 1, "# Vim inbox")
    end
    if vim.fn.writefile(lines, M.inbox, "a") ~= 0 then
      vim.notify("Couldn't write " .. M.inbox, vim.log.levels.ERROR, { title = "Habit capture" })
      return
    end
    vim.notify(
      private and "Captured the note only (private buffer)" or "Captured",
      vim.log.levels.INFO,
      { title = "Habit capture" }
    )
  end)
end

function M.open_inbox()
  vim.cmd.edit(vim.fn.fnameescape(M.inbox))
end

function M.setup()
  vim.on_key(on_key, vim.api.nvim_create_namespace("habit_capture"))
  vim.api.nvim_create_user_command("VimCapture", function()
    M.capture(":")
  end, { desc = "Capture the last keys to the Vim inbox" })
  vim.api.nvim_create_user_command("VimInbox", M.open_inbox, { desc = "Open the Vim inbox" })
end

return M
