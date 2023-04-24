local lib = require("neotest.lib")
local logger = require("neotest.logging")
local ok, async = pcall(require, "nio")
if not ok then async = require("neotest.async") end

local utils = require("neotest-minitest.utils")

---@class neotest.Adapter
---@field name string
local NeotestAdapter = { name = "neotest-minitest" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
NeotestAdapter.root = lib.files.match_root_pattern("Gemfile", ".rspec", ".gitignore")

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path)
  return vim.endswith(file_path, "_test.rb")
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function NeotestAdapter.filter_dir(name, rel_path, root)
  local _, count = rel_path:gsub("/", "")
  if rel_path:match("test") or count < 1 then return true end
  return false
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(file_path)
  local query = [[
    ; Classes that inherit from Minitest::Test
    ((
      class
      name: (constant) @namespace.name
      (superclass (scope_resolution) @superclass (#match? @superclass "^Minitest::Test"))
    )) @namespace.definition

    ; Methods that begin with test_
    ((
      method
      name: (identifier) @test.name (#match? @test.name "^test_")
    )) @test.definition

    ; rails unit test classes
    ((
        class
        name: (constant) @namespace.name
        (superclass (scope_resolution) @superclass (#match? @superclass "ActiveSupport::TestCase$"))
    )) @namespace.definition

    ((
      call
      method: (identifier) @func_name (#match? @func_name "^(test)$")
      arguments: (argument_list (_) @test.name)
    )) @test.definition

  ]]

  return lib.treesitter.parse_positions(file_path, query, {
    nested_tests = true,
    require_namespaces = true,
    position_id = "require('neotest-minitest.utils').generate_treesitter_id",
  })
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function NeotestAdapter.build_spec(args)
  local script_args = {}
  local position = args.tree:data()
  local results_path = async.fn.tempname()

  local name_mappings = utils.get_mappings(args.tree)

  local function run_by_filename()
    table.insert(script_args, position.path)
  end

  local function run_by_name()
    local full_name = utils.full_test_name(args.tree, position.name)
    table.insert(script_args, position.path)
    table.insert(script_args, "--name")
    -- https://chriskottom.com/articles/command-line-flags-for-minitest-in-the-raw/
    table.insert(script_args, "/" .. full_name:gsub("%#", "\\#") .. "/")
  end

  if position.type == "file" then run_by_filename() end

  if position.type == "test" or (position.type == "namespace" and vim.bo.filetype ~= "neotest-summary") then
    run_by_name()
  end

  local ruby_cmd = vim.tbl_flatten({
    "bundle",
    "exec",
    "ruby",
    "-Itest",
  })

  local command = vim.tbl_flatten({
    ruby_cmd,
    script_args,
    "-v",
  })

  return {
    cwd = nil,
    command = command,
    context = {
      results_path = results_path,
      pos_id = position.id,
      name_mappings = name_mappings,
    },
  }
end

function NeotestAdapter._parse_test_output(output, name_mappings)
  local results = {}
  local test_pattern = "(%w+#[%w_]+)%s*=%s*[%d.]+%s*s%s*=%s*([F.])"
  local error_pattern = "Failure:%s*([%w#_]+)%s*%[([^%]]+)%]:%s*Expected:%s*(.-)%s*Actual:%s*(.-)%s\n\n"

  for test_name, status in string.gmatch(output, test_pattern) do
    local pos_id = name_mappings[test_name]
    results[pos_id] = {
      status = status == "F" and "failed" or "passed",
    }
  end

  for test_name, filepath, expected, actual in string.gmatch(output, error_pattern) do
    local line = tonumber(string.match(filepath, ":(%d+)$"))
    local message = string.format("Expected: %s\n  Actual: %s", expected, actual)
    local pos_id = name_mappings[test_name]

    if results[pos_id] then
      results[pos_id].status = "failed"
      results[pos_id].errors = {
        {
          message = message,
          line = line,
        },
      }
    end
  end

  return results
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, result, tree)
  local success, output = pcall(lib.files.read, result.output)
  if not success then
    logger.error("neotest-minitest: could not read output: " .. output)
    return {}
  end

  output = utils.strip_ansi_escape_codes(output)
  local results = NeotestAdapter._parse_test_output(output, spec.context.name_mappings)

  return results
end

return NeotestAdapter
