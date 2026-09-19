-- The herdr multiplexer backend, with resize amounts in the right units.
--
-- Upstream's `smart-splits.mux.herdr` hands smart-splits' resize amount
-- (`default_amount`, a count of columns/rows) straight to `herdr pane resize`,
-- whose `--amount` is a *ratio* delta in 0.0-1.0. One <C-A-hjkl> press
-- therefore slams the split to herdr's clamp (0.5 -> 0.9) instead of nudging
-- it. Scale the amount by the tab area first, and report the real zoom state
-- while we have the layout in hand (upstream always answers false).
--
-- Resolved by name via `multiplexer_integration`, which smart-splits requires
-- as `smart-splits.mux.<name>`; this config dir is on the runtimepath.

local herdr = require("smart-splits.mux.herdr")

local function herdr_bin()
  local bin = vim.env.HERDR_BIN_PATH
  return (bin ~= nil and bin ~= "") and bin or "herdr"
end

-- `pane edges` returns the direction booleans and the whole tab layout in one
-- call, so zoom state and area size cost no extra subprocess.
local function current_layout()
  local output, code = require("smart-splits.utils").system({ herdr_bin(), "pane", "edges", "--current" })
  if code ~= 0 or not output or #output == 0 then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, output)
  if not ok then
    return nil
  end

  return vim.tbl_get(decoded, "result", "edges", "layout")
end

---@type SmartSplitsMultiplexer
local M = vim.tbl_extend("force", {}, herdr)

function M.current_pane_is_zoomed()
  local layout = current_layout()
  return layout ~= nil and layout.zoomed == true
end

function M.resize_pane(direction, amount)
  local layout = current_layout()
  local area = layout and layout.area
  if not area then
    return false
  end

  -- Ratios are relative to the enclosing split, but its rect is only
  -- identifiable by walking the tree; the tab area matches it in the common
  -- case and errs small (a gentler nudge) when splits are nested.
  local size = (direction == "left" or direction == "right") and area.width or area.height
  if not size or size <= 0 then
    return false
  end

  return herdr.resize_pane(direction, amount / size)
end

return M
