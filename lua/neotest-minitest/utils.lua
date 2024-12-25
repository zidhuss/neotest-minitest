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
---@param parents neotest.Position[] Parent positions for the position
---@return string
M.generate_treesitter_id = function(position, parents)
  local cwd = async.fn.getcwd()
  local test_path = "." .. replace_paths(position.path, cwd, "")
  -- Treesitter starts line numbers from 0 so we subtract 1
  local id = test_path .. separator .. (tonumber(position.range[1]) + 1)

  return id
end

---@param s string
local function unquote(s)
  local r, _ = s:gsub("^['\"]*([^'\"]*)['\"]*$", "%1")
  return r
end

M.full_spec_name = function(tree)
  local name = unquote(tree:data().name)
  local namespaces = {}
  local num_namespaces = 0

  for parent_node in tree:iter_parents() do
    local data = parent_node:data()
    if data.type == "namespace" then
      table.insert(namespaces, 1, unquote(parent_node:data().name))
      num_namespaces = num_namespaces + 1
    else
      break
    end
  end

  if num_namespaces == 0 then return name end

  -- build result
  local result = ""
  -- assemble namespaces
  result = table.concat(namespaces, "::")
  -- add # separator
  result = result .. "#"
  -- add test_ prefix
  result = result .. "test_"
  -- add index
  for i, child_tree in ipairs(tree:parent():children()) do
    for _, node in child_tree:iter_nodes() do
      if node:data().id == tree:data().id then result = result .. string.format("%04d", i) end
    end
  end
  -- add _[name]
  result = result .. "_" .. name

  return result
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
      local full_spec_name = M.full_spec_name(tree)
      mappings[full_spec_name] = data.id

      local full_test_name = M.full_test_name(tree)
      mappings[full_test_name] = data.id
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
