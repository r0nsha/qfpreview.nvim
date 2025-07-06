local util = require("qfpreview.util")

local M = {}

local group = vim.api.nvim_create_augroup("QuickfixPreview", { clear = true })

---@param config? qfpreview.Config
function M.setup(config)
  local preview = require("qfpreview.preview"):new(config)

  local refresh = util.throttle(function()
    preview:refresh()
  end, preview.config.throttle)

  ---@type integer?
  local qfbuf

  vim.api.nvim_create_autocmd({ "WinEnter", "CursorMoved" }, {
    group = group,
    callback = function(args)
      if vim.bo.filetype == "qf" then
        qfbuf = args.buf
        refresh()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    group = group,
    callback = function(args)
      if args.buf == qfbuf then
        refresh:cancel()
        preview:close()
        qfbuf = nil
      end
    end,
  })
end

return M
