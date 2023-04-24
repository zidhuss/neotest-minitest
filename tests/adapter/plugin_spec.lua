local plugin = require("neotest-minitest")

describe("is_test_file", function()
  it("matches test files", function()
    assert.equals(true, plugin.is_test_file("./test/foo_test.rb"))
  end)

  it("does not match plain ruby files", function()
    assert.equals(false, plugin.is_test_file("./lib/foo.rb"))
  end)
end)

describe("filter_dir", function()
  -- note that even though these tests suggest that `engine/things/spec` would be approved,
  -- `engine/things` would return false, so `engine/things/spec` would never be searched by
  -- neotest
  local root = "/home/name/projects"
  it("allows test", function()
    assert.equals(true, plugin.filter_dir("test", "test", root))
  end)
  it("allows sub directories one deep (for engines)", function()
    assert.equals(true, plugin.filter_dir("test_engine", "test_engine", root))
  end)
  it("allows paths that contain test", function()
    assert.equals(true, plugin.filter_dir("test", "test_engine/test", root))
  end)
  it("allows a long path with test at the start", function()
    assert.equals(true, plugin.filter_dir("billing_service", "test/controllers/billing_service", root))
  end)
  it("disallows paths without test, more that one sub dir deep", function()
    assert.equals(false, plugin.filter_dir("models", "app/models", root))
  end)
end)
