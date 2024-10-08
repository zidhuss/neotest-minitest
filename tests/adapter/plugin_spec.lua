local plugin = require("neotest-minitest")

describe("is_test_file", function()
  it("matches Rails-style test file", function()
    assert.equals(true, plugin.is_test_file("./test/foo_test.rb"))
  end)

  it("matches minitest-style test file", function()
    assert.equals(true, plugin.is_test_file("./test/test_foo.rb"))
  end)

  it("does not match plain ruby files", function()
    assert.equals(false, plugin.is_test_file("./lib/foo.rb"))
  end)
end)

describe("filter_dir", function()
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
  it("allows paths without test, more that one sub dir deep", function()
    assert.equals(true, plugin.filter_dir("models", "app/models", root))
  end)
  it("disallows the vendor directory", function()
    assert.equals(false, plugin.filter_dir("vendor", "vendor", root))
  end)
end)
