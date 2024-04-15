local ok, async = pcall(require, "nio")
if not ok then async = require("neotest.async") end

local logger = require("neotest.logging")

local M = {}
local separator = "::"

--- Replace paths in a string
---@param str string
---@param what string
---@param with string
---@return string
local function replace_paths(str, what, with)
  -- Taken from: https://stackoverflow.com/a/29379912/3250992
  what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
  with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
  return string.gsub(str, what, with)
end

-- We are considering test class names without their module, but
-- Lua's built-in pattern matching isn't powerful enough to do so. Instead
-- we match on the full name, including module, and strip it off here.
--
-- @param test_name string
-- @return string
M.replace_module_namespace = function(test_name)
  return test_name.gsub(test_name, "%w+::", "")
end

---@param position neotest.Position The position to return an ID for
---@param namespace neotest.Position[] Any namespaces the position is within
---@return string
M.generate_treesitter_id = function(position)
  local cwd = async.fn.getcwd()
  local test_path = "." .. replace_paths(position.path, cwd, "")
  -- Treesitter starts line numbers from 0 so we subtract 1
  local id = test_path .. separator .. (tonumber(position.range[1]) + 1)

  return id
end

M.full_test_name = function(tree)
  local name = tree:data().name
  local parent_tree = tree:parent()
  if not parent_tree or parent_tree:data().type == "file" then return name end
  local parent_name = parent_tree:data().name

  -- For rails and spec tests
  if not name:match("^test_") then name = "test_" .. name end

  return parent_name .. "#" .. name:gsub(" ", "_")
end

M.escaped_full_test_name = function(tree)
  local full_name = M.full_test_name(tree)
  return full_name:gsub("([?#])", "\\%1")
end

M.get_mappings = function(tree)
  -- get the mappings for the current node and its children
  local mappings = {}
  local function name_map(tree)
    local data = tree:data()
    if data.type == "test" then
      local full_name = M.full_test_name(tree)
      mappings[full_name] = data.id
    end

    for _, child in ipairs(tree:children()) do
      name_map(child)
    end
  end
  name_map(tree)

  return mappings
end

M.strip_ansi_escape_codes = function(str)
  return str:gsub("\27%[%d+m", "")
end

return M
