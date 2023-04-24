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

  describe("_parse_test_output", function()
    assert:set_parameter("TableFormatLevel", -1)
    describe("single failing test", function()
      local output = [[
ClassicTest#test_addition = 0.00 s = F


Failure:
ClassicTest#test_addition [/Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:7]:
Expected: 3
  Actual: 2


    ]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["ClassicTest#test_addition"] = "testing" })

        assert.are.same({
          ["testing"] = { status = "failed", errors = { { message = "Expected: 3\n  Actual: 2", line = 7 } } },
        }, results)
      end)
    end)

    describe("single passing test", function()
      local output = [[
ClassicTest#test_addition = 0.00 s = .
      ]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["ClassicTest#test_addition"] = "testing" })

        assert.are.same({
          ["testing"] = { status = "passed" },
        }, results)
      end)
    end)

    describe("failing and passing tests", function()
      local output = [[
ClassicTest#test_subtraction = 0.00 s = F


Failure:
ClassicTest#test_subtraction [/Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:10]:
Expected: 1
  Actual: 0


rails test Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:9

ClassicTest#test_addition = 0.00 s = .
      ]]
      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, {
          ["ClassicTest#test_subtraction"] = "testing_subtraction",
          ["ClassicTest#test_addition"] = "testing_addition",
        })

        assert.are.same({
          ["testing_subtraction"] = {
            status = "failed",
            errors = { { message = "Expected: 1\n  Actual: 0", line = 10 } },
          },
          ["testing_addition"] = { status = "passed" },
        }, results)
      end)
    end)
  end)

  describe("multiple failing tests", function()
    output = [[
ClassicTest#test_addition = 0.00 s = F


Failure:
ClassicTest#test_addition [/Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:7]:
Expected: 5
  Actual: 2


rails test Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:6

ClassicTest#test_subtraction = 0.00 s = F


Failure:
ClassicTest#test_subtraction [/Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:10]:
Expected: 1
  Actual: 0


rails test Users/abry/src/nvim-neotest/neotest-minitest/tests/minitest_examples/classic_test.rb:9
      ]]

    it("parses the results correctly", function()
      local results = plugin._parse_test_output(output, {
        ["ClassicTest#test_addition"] = "testing_addition",
        ["ClassicTest#test_subtraction"] = "testing_subtraction",
      })

      assert.are.same({
        ["testing_addition"] = {
          status = "failed",
          errors = { { message = "Expected: 5\n  Actual: 2", line = 7 } },
        },
        ["testing_subtraction"] = {
          status = "failed",
          errors = { { message = "Expected: 1\n  Actual: 0", line = 10 } },
        },
      }, results)
    end)
  end)

  describe("multiple passing tests", function()
    local output = [[
ClassicTest#test_subtraction = 0.00 s = .
ClassicTest#test_addition = 0.00 s = .
      ]]
    it("parses the results correctly", function()
      local results = plugin._parse_test_output(output, {
        ["ClassicTest#test_subtraction"] = "testing_subtraction",
        ["ClassicTest#test_addition"] = "testing_addition",
      })

      assert.are.same({
        ["testing_subtraction"] = { status = "passed" },
        ["testing_addition"] = { status = "passed" },
      }, results)
    end)
  end)
end)
