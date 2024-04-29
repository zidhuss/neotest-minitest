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
    local tree = Tree.from_list({ id = "test", name = "test_example" }, function(pos)
      return pos.id
    end)
    assert.equals("test_example", utils.full_test_name(tree))
  end)

  it("returns the name of the test with the parent namespace", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "example" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace#test_example", utils.full_test_name(tree:children()[1]))
  end)

  it("prefixes the test with test_", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "example" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace#test_example", utils.full_test_name(tree:children()[1]))
  end)

  it("replaces spaces with underscores", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "this is a great test name" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace#test_this_is_a_great_test_name", utils.full_test_name(tree:children()[1]))
  end)

  it("shouldn't replace the quotes inside the test name", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "shouldn't remove our single quote" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace#test_shouldn't_remove_our_single_quote", utils.full_test_name(tree:children()[1]))
  end)
end)

describe("escaped_full_test_name", function()
  it("escapes # characters", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "#escaped_full_test_name should be escaped" },
    }, function(pos)
      return pos.id
    end)
    assert.equals(
      "namespace\\#test_\\#escaped_full_test_name_should_be_escaped",
      utils.escaped_full_test_name(tree:children()[1])
    )
  end)

  it("escapes ? characters", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "escaped? should be escaped" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace\\#test_escaped\\?_should_be_escaped", utils.escaped_full_test_name(tree:children()[1]))
  end)

  it("escapes multiple ? and # characters", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "test", name = "#escaped? should be escaped" },
    }, function(pos)
      return pos.id
    end)
    assert.equals("namespace\\#test_\\#escaped\\?_should_be_escaped", utils.escaped_full_test_name(tree:children()[1]))
  end)
end)

describe("get_mappings", function()
  it("gives full test name for nodes of tree", function()
    local tree = Tree.from_list({
      { id = "namespace", name = "namespace", type = "namespace" },
      { id = "namespace_test_example", name = "test_example", type = "test" },
    }, function(pos)
      return pos.id
    end)

    local mappings = utils.get_mappings(tree)

    assert.equals("namespace_test_example", mappings["namespace#test_example"])
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

describe("replace_module_namespace", function()
  it("removes module namespace", function()
    local input = "Foo::Bar"

    assert.equals("Bar", utils.replace_module_namespace(input))
  end)
end)
