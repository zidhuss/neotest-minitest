local plugin = require("neotest-minitest")
local async = require("nio.tests")

describe("Rails System Test", function()
  assert:set_parameter("TableFormatLevel", -1)
  describe("discover_positions SystemTestCase", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/system_test_case.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "system_test_case.rb",
          path = test_path,
          range = { 0, 0, 6, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/system_test_case.rb::3",
            name = "RailsSystemTest",
            path = test_path,
            range = { 2, 0, 5, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/system_test_case.rb::4",
              name = "should pass",
              path = test_path,
              range = { 3, 2, 4, 5 },
              type = "test",
            },
          },
        },
      }
      assert.are.same(positions, expected_positions)
    end)
  end)

  describe("discover_positions ApplicationSystemTestCase", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/rails_system_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "rails_system_test.rb",
          path = test_path,
          range = { 0, 0, 6, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/rails_system_test.rb::3",
            name = "RailsSystemTest",
            path = test_path,
            range = { 2, 0, 5, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/rails_system_test.rb::4",
              name = "should pass",
              path = test_path,
              range = { 3, 2, 4, 5 },
              type = "test",
            },
          },
        },
      }
      assert.are.same(positions, expected_positions)
    end)
  end)

  describe("discover_positions namespaced ApplicationSystemTestCase", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/namespaced_rails_system_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "namespaced_rails_system_test.rb",
          path = test_path,
          range = { 0, 0, 6, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/namespaced_rails_system_test.rb::3",
            name = "EmailsTest",
            path = test_path,
            range = { 2, 0, 5, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/namespaced_rails_system_test.rb::4",
              name = "should pass",
              path = test_path,
              range = { 3, 2, 4, 5 },
              type = "test",
            },
          },
        },
      }
      assert.are.same(positions, expected_positions)
    end)
  end)
end)
