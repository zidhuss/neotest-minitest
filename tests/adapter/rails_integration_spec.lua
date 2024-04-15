local plugin = require("neotest-minitest")
local async = require("nio.tests")

describe("Rails Integration Test", function()
  describe("discover_positions", function()
    async.it("should discover the position for the tests", function()
      local test_path = vim.loop.cwd() .. "/tests/minitest_examples/rails_integration_test.rb"
      local positions = plugin.discover_positions(test_path):to_list()
      local expected_positions = {
        {
          id = test_path,
          name = "rails_integration_test.rb",
          path = test_path,
          range = { 0, 0, 18, 0 },
          type = "file",
        },
        {
          {
            id = "./tests/minitest_examples/rails_integration_test.rb::15",
            name = "RailsIntegrationTest",
            path = test_path,
            range = { 14, 0, 17, 3 },
            type = "namespace",
          },
          {
            {
              id = "./tests/minitest_examples/rails_integration_test.rb::16",
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

  describe("_parse_test_output", function()
    describe("single passing test", function()
      local output = [[
UserControllerTest#test_is_site-admin = 0.25 s = .
      ]]
      it("parses the results correctly", function()
        local results = plugin._parse_test_output(output, { ["UserControllerTest#test_is_site-admin"] = "testing" })

        assert.are.same({ ["testing"] = { status = "passed" } }, results)
      end)
    end)

    -- UserOnboarding::UserControllerTest#test_should_get_update = 0.25 s = E
    describe("single error test", function()
      local output = [[
CaregiverOnboarding::UserInfoControllerTest#test_should_get_edit = 0.00 s = E


Error:
CaregiverOnboarding::UserInfoControllerTest#test_should_get_edit:
NameError: undefined local variable or method `foobar' for an instance of CaregiverOnboarding::UserInfoControllerTest
    test/controllers/caregiver_onboarding/user_info_controller_test.rb:5:in `block in <class:UserInfoControllerTest>'
      ]]
      it("parses the results correctly", function()
        local results = plugin._parse_test_output(
          output,
          { ["CaregiverOnboarding::UserInfoControllerTest#test_should_get_edit"] = "testing" }
        )
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
  end)
end)
