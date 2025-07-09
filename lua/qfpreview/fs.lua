local M = {}

---@param path string
---@param cwd string
---@return string
function M.normalize_path(path, cwd)
  if path == cwd then
    return "."
  end

  -- if `path` is a subpath of `cwd`, remove `cwd` to make it relative
  if path:sub(1, #cwd) == cwd then
    return path:sub(#cwd + 2)
  end

  -- if `path` is under the home directory, return it with `~`
  local home = os.getenv("HOME")
  if home then
    if path == home then
      return "~"
    end

    if path:sub(1, #home) == home then
      return "~/" .. path:sub(#home + 2)
    end
  end

  return path
end

return M
