-- The hand-off (GLOSSARY.md › Prompt pane): when Claude opens a dialog only its own pane
-- answers, the prompt pane zooms and focuses Claude's pane, and takes focus back once
-- Claude is at its input box again. Only from a focused prompt pane: a Claude blocked
-- while you're elsewhere is agent-notify's to report.
local M = {}

-- The trip under way: { agent = pane id, armed = whether a dialog has been seen,
-- resume = what to do once back, abandon = what to do if you leave it }.
local trip = nil
local timer = nil
-- What Claude's pane shows, given by config.prompt at open: fun(cb(screen?, agent?, err?)).
local read_screen = nil

---@param reader fun(cb: fun(screen?: "idle"|"working"|"blocked"|"dialog", agent?: table, err?: string))
function M.setup(reader)
  read_screen = reader
end

-- Whether a dialog is up in Claude's pane, in place of its input box.
local function dialog_up(screen)
  return screen == "blocked" or screen == "dialog"
end

-- Whether this dialog sends you to Claude's pane. Every one does, for now; the place
-- to narrow it to the dialogs the prompt pane can't answer itself. Only for going:
-- coming back waits for any dialog to close.
---@param screen "idle"|"working"|"blocked"|"dialog"
function M.wants(screen)
  return dialog_up(screen)
end

function M.active()
  return trip ~= nil
end

-- herdr's focused pane, across every tab and workspace.
---@param cb fun(pane_id?: string)
local function focused(cb)
  vim.system(
    { "herdr", "api", "snapshot" },
    { text = true },
    vim.schedule_wrap(function(out)
      local ok, decoded = pcall(vim.json.decode, out.stdout or "")
      cb(ok and type(decoded) == "table" and vim.tbl_get(decoded, "result", "snapshot", "focused_pane_id") or nil)
    end)
  )
end

-- Zooming a pane focuses it too, and its tab; the tab's zoom moves to it. Waited for,
-- so the first check after it sees the focus it set.
local function zoom(pane_id)
  return vim.system({ "herdr", "pane", "zoom", pane_id, "--on" }):wait().code == 0
end

local function finish(how)
  local done = trip
  trip = nil
  if timer then
    timer:stop()
  end
  local cb = done and done[how]
  if cb then
    cb()
  end
end

-- Every half second while away: back at the input box takes you back; leaving
-- Claude's pane abandons the trip, unless the dialog was answered by then.
local function watch()
  timer = timer or vim.uv.new_timer()
  timer:start(
    500,
    0,
    vim.schedule_wrap(function()
      if not trip then
        return
      end
      focused(function(pane)
        read_screen(function(screen)
          if not trip then
            return
          end
          local answered = trip.armed and screen and not dialog_up(screen)
          trip.armed = trip.armed or dialog_up(screen)
          if pane == trip.agent and answered then
            zoom(vim.env.HERDR_PANE_ID)
            return finish("resume")
          elseif pane == vim.env.HERDR_PANE_ID and answered then
            return finish("resume")
          elseif pane ~= trip.agent then
            return finish("abandon")
          end
          watch()
        end)
      end)
    end)
  )
end

-- Takes the trip to Claude's pane if this prompt pane is the focused one, calling
-- back with whether it did. A trip for a dialog already up is armed: it returns as
-- soon as Claude's input box is back. A manual one waits to see a dialog first.
---@param agent table Claude's pane, from `herdr pane list`
---@param opts { armed?: boolean, resume?: fun(), abandon?: fun() }
---@param cb? fun(went: boolean)
function M.go(agent, opts, cb)
  if trip then
    return cb and cb(false)
  end
  focused(function(pane)
    if trip or not read_screen or not vim.env.HERDR_PANE_ID or pane ~= vim.env.HERDR_PANE_ID then
      return cb and cb(false)
    end
    if not zoom(agent.pane_id) then
      return cb and cb(false)
    end
    trip = { agent = agent.pane_id, armed = opts.armed, resume = opts.resume, abandon = opts.abandon }
    watch()
    if cb then
      cb(true)
    end
  end)
end

return M
