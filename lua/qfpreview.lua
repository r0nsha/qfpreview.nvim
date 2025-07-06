local M = {}

local group = vim.api.nvim_create_augroup("QuickfixPreview", { clear = true })

---@param config? qfpreview.Config
function M.setup(config)
  local preview = require("lib.preview"):new(config)

  vim.api.nvim_create_autocmd({ "WinEnter", "CursorMoved" }, {
    group = group,
    callback = function()
      if vim.bo.filetype == "qf" then
        preview:refresh()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    group = group,
    callback = function()
      if vim.bo.filetype == "qf" then
        preview:close()
      end
    end,
  })
end

return M
