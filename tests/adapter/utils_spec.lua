local utils = require("neotest-minitest.utils")

describe("generate_treesitter_id", function()
  it("forms an id", function()
    local ts = {
      name = "'adds two numbers together'",
      path = vim.loop.cwd() .. "/tests/classic/classic_test.rb",
      range = {
        1,
        2,
        3,
        5,
      },
      type = "test",
    }

    assert.equals("./tests/classic/classic_test.rb::2", utils.generate_treesitter_id(ts))
  end)
end)
