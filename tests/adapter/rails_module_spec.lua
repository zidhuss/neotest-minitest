local plugin = require("neotest-minitest")
local async = require("nio.tests")

describe("Rails Module Test", function()
  assert:set_parameter("TableFormatLevel", -1)
  describe("discover_positions", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/rails_module_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "rails_module_test.rb",
          path = test_path,
          range = { 0, 0, 21, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/rails_module_test.rb::18",
            name = "FooControllerTest",
            path = test_path,
            range = { 17, 0, 20, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/rails_module_test.rb::19",
              name = "should pass",
              path = test_path,
              range = { 18, 2, 19, 5 },
              type = "test",
            },
          },
        },
      }
      assert.are.same(expected_positions, positions)
    end)
  end)
  describe("_parse_test_output", function()
    describe("single error test", function()
      local output = [[
CaregiverOnboarding::UserInfoControllerTest#test_should_get_edit = 0.00 s = E


Error:
CaregiverOnboarding::UserInfoControllerTest#test_should_get_edit:
NameError: undefined local variable or method `foobar' for an instance of CaregiverOnboarding::UserInfoControllerTest
    test/controllers/caregiver_onboarding/user_info_controller_test.rb:5:in `block in <class:UserInfoControllerTest>'
      ]]
      it("parses the results correctly", function()
        local results =
          plugin._parse_test_output(output, { ["UserInfoControllerTest#test_should_get_edit"] = "testing" })
        assert.are.same({
          ["testing"] = {
            status = "failed",
            errors = {
              {
                line = 4,
                message = "NameError: undefined local variable or method `foobar' for an instance of CaregiverOnboarding::UserInfoControllerTest",
              },
            },
          },
        }, results)
      end)
    end)

    describe("multiple passing tests", function()
      local output = [[
Foo::RailsUnitTest#test_subtracts_two_numbers = 0.00 s = .
Foo::RailsUnitTest#test_adds_two_numbers = 0.00 s = .
    ]]

      it("parses the results correctly", function()
        -- We end up only parsing the class name, not the module
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

    describe("single failing test", function()
      local output = [[
CaregiverOnboarding::UserInfoControllerTest#test_throwaway = 0.07 s = F


Failure:
CaregiverOnboarding::UserInfoControllerTest#test_throwaway [test/controllers/caregiver_onboarding/user_info_controller_test.rb:21]:
Expected: 2
  Actual: 4


    ]]

      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["UserInfoControllerTest#test_throwaway"] = "testing" })

        assert.are.same({
          ["testing"] = { status = "failed", errors = { { message = "Expected: 2\n  Actual: 4", line = 20 } } },
        }, results)
      end)
    end)
  end)
end)
