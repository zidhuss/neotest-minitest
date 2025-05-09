local lib = require("neotest.lib")
local logger = require("neotest.logging")
local async = require("neotest.async")

local config = require("neotest-minitest.config")
local utils = require("neotest-minitest.utils")

---@class neotest.Adapter
---@field name string
local NeotestAdapter = { name = "neotest-minitest" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
NeotestAdapter.root = lib.files.match_root_pattern("Gemfile", ".gitignore")

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path)
  return vim.endswith(file_path, "_test.rb") or string.match(file_path, "/test_.+%.rb$") ~= nil
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function NeotestAdapter.filter_dir(name, rel_path, root)
  return name ~= "vendor"
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

    ; System tests that inherit from ApplicationSystemTestCase
    ((
        class 
        name: [
          (constant) @namespace.name 
          (scope_resolution scope: (constant) name: (constant) @namespace.name)
        ]
        (superclass) @superclass (#match? @superclass "(ApplicationSystemTestCase)$" )
    )) @namespace.definition

    ; Methods that begin with test_
    ((
      method
      name: (identifier) @test.name (#match? @test.name "^test_")
    )) @test.definition

    ; rails unit classes
    ((
        class
        name: [
          (constant) @namespace.name
          (scope_resolution scope: (constant) name: (constant) @namespace.name)
        ]
        (superclass (scope_resolution) @superclass (#match? @superclass "(::IntegrationTest|::TestCase|::SystemTestCase)$"))
    )) @namespace.definition

    ((
      call
      method: (identifier) @func_name (#match? @func_name "^(test)$")
      arguments: (argument_list (string (string_content) @test.name))
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
  local results_path = config.results_path()
  local spec_path = config.transform_spec_path(position.path)

  local name_mappings = utils.get_mappings(args.tree)

  local function run_by_filename()
    table.insert(script_args, spec_path)
  end

  local function run_by_name()
    local full_name = utils.escaped_full_test_name(args.tree, position.name)
    table.insert(script_args, spec_path)
    table.insert(script_args, "--name")
    -- https://chriskottom.com/articles/command-line-flags-for-minitest-in-the-raw/
    table.insert(script_args, "/" .. full_name .. "/")
  end

  if position.type == "file" or position.type == "dir" then run_by_filename() end

  local function dap_strategy(command)
    local port = math.random(49152, 65535)
    port = config.port or port

    local rdbg_args = {
      "-O",
      "--port",
      port,
      "-c",
      "-e",
      "cont",
      "--",
    }

    for i = 1, #command do
      rdbg_args[#rdbg_args + 1] = command[i]
    end

    return {
      name = "Neotest Debugger",
      type = "ruby",
      bundle = "bundle",
      localfs = true,
      request = "attach",
      args = rdbg_args,
      command = "rdbg",
      cwd = "${workspaceFolder}",
      port = port,
    }
  end

  if position.type == "test" or position.type == "namespace" then run_by_name() end

  local command = vim.tbl_flatten({
    config.get_test_cmd(),
    script_args,
    "-v",
  })

  if args.strategy == "dap" then
    return {
      command = command,
      context = {
        results_path = results_path,
        pos_id = position.id,
        name_mappings = name_mappings,
      },
      strategy = 
      
      (command),
    }
  else
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
end

function NeotestAdapter._parse_test_output(output, name_mappings)
  local results = {}
  local test_pattern = "(%w+#[%S]+)%s*=%s*[%d.]+%s*s%s*=%s*([FE.])"
  local failure_pattern = "Failure:%s*([%w#_:]+)%s*%[([^%]]+)%]:%s*Expected:%s*(.-)%s*Actual:%s*(.-)%s"
  local error_pattern = "Error:%s*([%w:#_]+):%s*(.-)\n[%w%W]-%.rb:(%d+):"
  local traceback_pattern = "(%d+:[^:]+:%d+:in `[^']+')%s+([^:]+):(%d+):(in `[^']+':[^\n]+)"

  for last_traceback, file_name, line_str, message in string.gmatch(output, traceback_pattern) do
    local line = tonumber(line_str)
    for _, pos_id in pairs(name_mappings) do
      results[pos_id] = {
        status = "failed",
        errors = {
          {
            message = message,
            line = line - 1,
          },
        },
      }
    end
  end

  for test_name, status in string.gmatch(output, test_pattern) do
    local pos_id = name_mappings[test_name]

    if pos_id then results[pos_id] = {
      status = status == "." and "passed" or "failed",
    } end
  end
  for test_name, filepath, expected, actual in string.gmatch(output, failure_pattern) do
    test_name = utils.replace_module_namespace(test_name)

    local line = tonumber(string.match(filepath, ":(%d+)$"))
    local message = string.format("Expected: %s\n  Actual: %s", expected, actual)
    local pos_id = name_mappings[test_name]

    if results[pos_id] then
      results[pos_id].status = "failed"
      results[pos_id].errors = {
        {
          message = message,
          line = line - 1,
        },
      }
    end
  end

  for test_name, message, line_str in string.gmatch(output, error_pattern) do
    test_name = utils.replace_module_namespace(test_name)
    local line = tonumber(line_str)
    local pos_id = name_mappings[test_name]
    if results[pos_id] then
      results[pos_id].status = "failed"
      results[pos_id].errors = {
        {
          message = message,
          line = line - 1, -- neovim lines are 0 indexed
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

local is_callable = function(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

setmetatable(NeotestAdapter, {
  __call = function(_, opts)
    if is_callable(opts.test_cmd) then
      config.get_test_cmd = opts.test_cmd
    elseif opts.test_cmd then
      config.get_test_cmd = function()
        return opts.test_cmd
      end
    end
    if is_callable(opts.transform_spec_path) then
      config.transform_spec_path = opts.transform_spec_path
    elseif opts.transform_spec_path then
      config.transform_spec_path = function()
        return opts.transform_spec_path
      end
    end
    if is_callable(opts.results_path) then
      config.results_path = opts.results_path
    elseif opts.results_path then
      config.results_path = function()
        return opts.results_path
      end
    end
    return NeotestAdapter
  end,
})

return NeotestAdapter
