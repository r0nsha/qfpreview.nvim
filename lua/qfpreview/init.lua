local util = require("qfpreview.util")

local M = {}

local group = vim.api.nvim_create_augroup("QuickfixPreview", { clear = true })

---@param config? qfpreview.Config
function M.setup(config)
  local preview = require("qfpreview.preview"):new(config)

  ---@param qfwin integer
  local refresh = util.throttle(function(qfwin)
    preview:refresh(qfwin)
  end, preview.config.throttle)

  ---@type integer?
  local qfwin

  vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved", "WinResized" }, {
    group = group,
    callback = function()
      if vim.bo.filetype == "qf" then
        qfwin = vim.api.nvim_get_current_win()
        refresh(qfwin)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    group = group,
    callback = function(args)
      local curr_win = args.event == "WinLeave" and vim.fn.win_getid() or tonumber(args.match)
      if curr_win == qfwin then
        refresh:cancel()
        preview:close()
        qfwin = nil
      end
    end,
  })
end

return M
