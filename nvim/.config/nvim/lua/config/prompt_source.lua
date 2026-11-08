-- blink.cmp source for the prompt pane (lua/config/prompt.lua): /skill and @file, as
-- Claude's own input offers them. Registered in lua/plugins/blink.lua.
local M = {}

local limit = 50

function M.new()
  return setmetatable({ candidates = {} }, { __index = M })
end

function M:get_trigger_characters()
  return { "/", "@", ".", ":" }
end

local function query(context)
  local before = context.line:sub(1, context.cursor[2])
  -- Only a prompt's opening word runs as a command. Past that, Claude just reads the name
  -- and has to invoke the skill itself, so only the skills it can invoke are offered.
  local skill = before:match("^/([%w:_-]*)$")
  if skill and context.cursor[1] == 1 then
    return "skill", skill
  end
  local listed = skill or before:match("%s/([%w:_-]*)$")
  if listed then
    return "listed_skill", listed
  end
  local file = before:match("^@(%S*)$") or before:match("%s@(%S*)$")
  if file then
    return "file", file
  end
end

-- The newest listing in the project's transcripts, since a session only writes its own
-- on its first prompt, which is when a skill is most likely to be wanted.
local function listed_skills(cwd)
  local dir = "~/.claude*/projects/" .. cwd:gsub("%W", "-")
  local paths = vim.fn.glob(dir .. "/*.jsonl", false, true)
  table.sort(paths, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  for _, path in ipairs(vim.list_slice(paths, 1, 5)) do
    local names = {}
    for _, line in ipairs(vim.fn.readfile(path)) do
      if line:find('"skill_listing"', 1, true) then
        local ok, entry = pcall(vim.json.decode, line)
        vim.list_extend(names, ok and vim.tbl_get(entry, "attachment", "names") or {})
      end
    end
    if #names > 0 then
      return names
    end
  end
  return {}
end

-- The listing has plugin and bundled skills but not the disable-model-invocation ones,
-- which only a scan of the skill directories finds.
local function skills(cwd)
  local names = listed_skills(cwd)
  for _, dir in ipairs({ "~/.claude", cwd .. "/.claude" }) do
    for _, path in ipairs(vim.fn.glob(dir .. "/skills/*/SKILL.md", false, true)) do
      table.insert(names, vim.fn.fnamemodify(path, ":h:t"))
    end
  end
  return names
end

-- Shortest first, so the bare @ opens on the top of the tree.
local function files(cwd, done)
  local cmd = { "fd", "--hidden", "--exclude", ".git", "--strip-cwd-prefix", "--max-results", "20000" }
  vim.system(cmd, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      local list = vim.split(result.stdout, "\n", { trimempty = true })
      table.sort(list, function(a, b)
        return #a < #b or (#a == #b and a < b)
      end)
      done(list)
    end)
  end)
end

-- Looked up as each / or @ opens, so a new skill or file shows up on the next one.
function M:refresh(kind, done)
  local agent = require("config.prompt").find_agent()
  local cwd = agent and agent.cwd or vim.fn.getcwd()
  local function store(list)
    self.candidates[kind] = list
    done()
  end
  if kind == "file" then
    files(cwd, store)
  else
    local names = kind == "skill" and skills(cwd) or listed_skills(cwd)
    table.sort(names)
    store(vim.fn.uniq(names))
  end
end

-- blink matches only the word under the cursor, which would drop everything before the
-- last / of a path. So the matching happens here, on the whole token, and filterText is
-- that word to let every result through; the source re-runs on each keystroke.
-- score_offset keeps this order, which blink's frecency would otherwise override by
-- floating anything accepted recently above a better match.
local function items(context, candidates, token)
  local found = token == "" and vim.list_slice(candidates, 1, limit)
    or vim.fn.matchfuzzy(candidates, token, { limit = limit })
  local line, col = context.cursor[1] - 1, context.cursor[2]
  local keyword = context.get_keyword()
  return vim.tbl_map(function(index)
    return {
      label = found[index],
      kind = require("blink.cmp.types").CompletionItemKind.File,
      filterText = keyword,
      score_offset = (limit - index) * 10,
      textEdit = {
        newText = found[index],
        range = {
          start = { line = line, character = col - #token },
          ["end"] = { line = line, character = col },
        },
      },
    }
  end, vim.fn.range(1, #found))
end

function M:get_completions(context, callback)
  local kind, token = query(context)
  if not kind then
    callback({ items = {}, is_incomplete_forward = true, is_incomplete_backward = true })
    return
  end
  local function respond()
    callback({
      items = items(context, self.candidates[kind], token),
      is_incomplete_forward = true,
      is_incomplete_backward = true,
    })
  end
  if token == "" or not self.candidates[kind] then
    self:refresh(kind, respond)
  else
    respond()
  end
end

return M
