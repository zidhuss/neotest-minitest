local M = {}

M.get_test_cmd = function()
  return vim.tbl_flatten({
    "bundle",
    "exec",
    "ruby",
    "-Itest",
  })
end

M.transform_spec_path = function(path)
  return path
end

M.results_path = function()
  return require("neotest.async").fn.tempname()
end

return M
