local plugin = require("neotest-minitest")
local async = require("nio.tests")

describe("Rails Unit Test", function()
  assert:set_parameter("TableFormatLevel", -1)
  describe("discover_positions", function()
    async.it("should discover the position fo the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/rails_unit_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "rails_unit_test.rb",
          path = test_path,
          range = { 0, 0, 13, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/rails_unit_test.rb::6",
            name = "RailsUnitTest",
            path = test_path,
            range = { 5, 0, 12, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/rails_unit_test.rb::7",
              name = "adds two numbers",
              path = test_path,
              range = { 6, 2, 8, 5 },
              type = "test",
            },
          },
          {
            {
              id = "./tests/minitest_examples/rails_unit_test.rb::10",
              name = "subtracts two numbers",
              path = test_path,
              range = { 9, 2, 11, 5 },
              type = "test",
            },
          },
        },
      }

      assert.are.same(positions, expected_positions)
    end)
  end)

  describe("_parse_test_output", function()
    describe("single failing test", function()
      local output = [[
RailsUnitTest#test_adds_two_numbers = 0.00 s = F


Failure:
RailsUnitTest#test_adds_two_numbers [/src/nvim-neotest/neotest-minitest/tests/minitest_examples/rails_unit_test.rb:8]:
Expected: 4
  Actual: 5


    ]]
      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["RailsUnitTest#test_adds_two_numbers"] = "testing" })

        assert.are.same(
          { ["testing"] = { status = "failed", errors = { { message = "Expected: 4\n  Actual: 5", line = 8 } } } },
          results
        )
      end)
    end)

    describe("single passing test", function()
      local output = [[
RailsUnitTest#test_subtracts_two_numbers = 0.00 s = .
]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["RailsUnitTest#test_subtracts_two_numbers"] = "testing" })

        assert.are.same({ ["testing"] = { status = "passed" } }, results)
      end)
    end)

    describe("failing and passing tests", function()
      local output = [[
RailsUnitTest#test_subtracts_two_numbers = 0.00 s = .
RailsUnitTest#test_adds_two_numbers = 0.00 s = F


Failure:
RailsUnitTest#test_adds_two_numbers [/neotest-minitest/tests/minitest_examples/rails_unit_test.rb:8]:
Expected: 4
  Actual: 5


    ]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, {
          ["RailsUnitTest#test_adds_two_numbers"] = "testing",
          ["RailsUnitTest#test_subtracts_two_numbers"] = "testing2",
        })

        assert.are.same({
          ["testing"] = { status = "failed", errors = { { message = "Expected: 4\n  Actual: 5", line = 8 } } },
          ["testing2"] = { status = "passed" },
        }, results)
      end)
    end)

    describe("multiple failing tests", function()
      local output = [[
RailsUnitTest#test_adds_two_numbers = 0.00 s = F


Failure:
RailsUnitTest#test_adds_two_numbers [/neotest-minitest/tests/minitest_examples/rails_unit_test.rb:8]:
Expected: 4
  Actual: 5


rails test Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/rails_unit_test.rb:7

RailsUnitTest#test_subtracts_two_numbers = 0.00 s = F


Failure:
RailsUnitTest#test_subtracts_two_numbers [/neotest-minitest/tests/minitest_examples/rails_unit_test.rb:11]:
Expected: 1
  Actual: 2


  ]]
      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, {
          ["RailsUnitTest#test_adds_two_numbers"] = "testing",
          ["RailsUnitTest#test_subtracts_two_numbers"] = "testing2",
        })

        assert.are.same({
          ["testing"] = { status = "failed", errors = { { message = "Expected: 4\n  Actual: 5", line = 8 } } },
          ["testing2"] = { status = "failed", errors = { { message = "Expected: 1\n  Actual: 2", line = 11 } } },
        }, results)
      end)
    end)

    describe("multiple passing tests", function()
      local output = [[
RailsUnitTest#test_subtracts_two_numbers = 0.00 s = .
RailsUnitTest#test_adds_two_numbers = 0.00 s = .
    ]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, {
          ["RailsUnitTest#test_adds_two_numbers"] = "testing",
          ["RailsUnitTest#test_subtracts_two_numbers"] = "testing2",
        })

        assert.are.same({
          ["testing"] = { status = "passed" },
          ["testing2"] = { status = "passed" },
        }, results)
      end)
    end)
  end)
end)
