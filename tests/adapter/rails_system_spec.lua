local plugin = require("neotest-minitest")
local async = require("nio.tests")

describe("Rails System Test", function()
  describe("discover_positions", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/rails_system_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "rails_system_test.rb",
          path = test_path,
          range = { 0, 0, 18, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/rails_system_test.rb::15",
            name = "RailsSystemTest",
            path = test_path,
            range = { 14, 0, 17, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/rails_system_test.rb::16",
              name = "should pass",
              path = test_path,
              range = { 15, 2, 16, 5 },
              type = "test",
            },
          },
        },
      }
      assert.are.same(positions, expected_positions)
    end)
  end)
end)
