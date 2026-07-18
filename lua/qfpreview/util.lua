local M = {}

---@class qfpreview.util.Throttled
---@operator call: ...
---@field cancel fun(self: qfpreview.util.Throttled)

---@generic P
---@param fn fun(...: P)
---@param delay_ms number
---@return qfpreview.util.Throttled | fun(...: P)
function M.throttle(fn, delay_ms)
  local timer = vim.uv.new_timer()

  ---@type qfpreview.util.Throttled
  local t = {
    cancel = function() end,
  }

  if not timer then
    setmetatable(t, {
      __call = function(_, ...)
        return fn(...)
      end,
    })
    return t
  end

  setmetatable(t, {
    __call = function(_, ...)
      local args = { ... }
      if not timer or timer:is_closing() then
        timer = vim.uv.new_timer()
      end
      timer:stop()
      timer:start(delay_ms, 0, function()
        vim.schedule(function()
          fn(unpack(args))
        end)
      end)
    end,
  })

  function t:cancel()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    timer = nil
  end

  return t
end

return M
