---@class qfpreview.Config
---@field ui qfpreview.Config.Ui
---@field opts qfpreview.Config.Opts

---@class qfpreview.Config.Ui
---@field height number | "fill" the height of the window
--- number will set the window to a fixed height
--- "fill" will make the window fill the editor's remaining space
---@field show_name boolean whether to show the buffer's name
---@field win vim.api.keyset.win_config additinonal window configuration

---@class qfpreview.Config.Opts
---@field throttle number the window's throttle time in milliseconds
---@field lsp boolean whether to enable lsp clients
---@field diagnostics boolean whether to enable diagnostics

local M = {}

---@type qfpreview.Config
M.defaults = {
  ui = {
    height = "fill",
    show_name = true,
    win = {},
  },
  opts = {
    throttle = 100,
    lsp = true,
    diagnostics = false,
  },
}

return M
