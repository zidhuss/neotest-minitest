local utils = require("neotest-minitest.utils")
local Tree = require("neotest.types.tree")

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

describe("full_test_name", function()
  it("returns the name of the test", function()
    local tree = Tree.from_list({ id = "test", name = "test" }, function(pos)
      return pos.id
    end)

    assert.equals("test", utils.full_test_name(tree))
  end)
  it("returns the name of the test with the parent namespace", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "test" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace#test", utils.full_test_name(tree:children()[1]))
  end)
end)

describe("get_mappings", function()
  it("gives full test name for nodes of tree", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "namespace_test", name = "test", type = "test" },
    }, function(pos)
      return pos.id
    end)

    local mappings = utils.get_mappings(tree)

    assert.equals("namespace_test", mappings["namespace#test"])
  end)

  it("give test name with no nesting", function()
    local tree = Tree.from_list({
      { id = "test_id", name = "test", type = "test" },
    }, function(pos)
      return pos.id
    end)

    local mappings = utils.get_mappings(tree)

    assert.equals("test_id", mappings["test"])
  end)
end)

describe("strip_ansi", function()
  it("strips ansi codes", function()
    local input = "This is \27[32mgreen\27[0m text!"

    assert.equals("This is green text!", utils.strip_ansi_escape_codes(input))
  end)
end)
