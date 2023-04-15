local plugin = require("neotest-minitest")
local async = require("plenary.async.tests")

describe("Classic Test", function()
  describe("discovers_positions", function()
    async.it("should discover the position of the test", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/classic_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()

      local expected_positions = {
        {
          id = test_path,
          name = "classic_test.rb",
          path = test_path,
          range = { 0, 0, 9, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/classic_test.rb::5",
            name = "ClassicTest",
            path = test_path,
            range = { 4, 0, 8, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/classic_test.rb::6",
              name = "test_addition",
              path = test_path,
              range = { 5, 2, 7, 5 },
              type = "test",
            },
          },
        },
      }

      assert.are.same(positions, expected_positions)
    end)
  end)
end)
