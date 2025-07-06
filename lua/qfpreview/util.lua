local M = {}

function M.find_qflist_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
      return win
    end
  end
  return nil
end

---@class qfpreview.util.Throttled
---@operator call: ...
---@field cancel fun(self: qfpreview.util.Throttled)

---@param fn function
---@param delay_ms number
---@return qfpreview.util.Throttled | fun()
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
      timer:stop()
      timer:start(delay_ms, 0, function()
        vim.schedule(function()
          fn(unpack(args))
        end)
      end)
    end,
  })

  function t:cancel()
    timer:stop()
  end

  return t
end

return M
