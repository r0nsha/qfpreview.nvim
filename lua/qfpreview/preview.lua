local fs = require("qfpreview.fs")
local util = require("qfpreview.util")

---@class qfpreview.Config
---@field height number | "fill" the height of the window
--- number will set the window to a fixed height
--- "fill" will make the window fill the editor's remaining space
---@field show_name boolean whether to show the buffer's name
---@field throttle number the window's throttle time in milliseconds
---@field win vim.api.keyset.win_config additinonal window configuration

---@class qfpreview.Preview
---@field config qfpreview.Config
---@field winnr number
---@field parsed_bufs table<number, boolean>
local Preview = {}
Preview.__index = Preview

---@type qfpreview.Config
local defaults = {
  height = "fill",
  show_name = true,
  throttle = 100,
  win = {},
}

---@param config? qfpreview.Config
---@return qfpreview.Preview
function Preview:new(config)
  local p = {
    config = vim.tbl_deep_extend("force", defaults, config or {}),
    win_id = nil,
    parsed_bufs = {},
  }
  setmetatable(p, self)
  self.__index = self
  return p
end

---@class QuickfixItem
---@field bufnr number
---@field module string
---@field lnum number
---@field end_lnum number
---@field col number
---@field end_col number
---@field vcol boolean
---@field pattern any
---@field text string
---@field type string
---@field valid boolean
---@field user_data any

---@return QuickfixItem
function Preview:curr_item()
  ---@type QuickfixItem
  local qflist = vim.fn.getqflist()
  return qflist[vim.fn.line(".")]
end

---@param item QuickfixItem
function Preview:highlight(item)
  if not self.parsed_bufs[item.bufnr] then
    vim.api.nvim_buf_call(item.bufnr, function()
      vim.cmd("filetype detect")
      pcall(vim.treesitter.start, item.bufnr)
    end)
    self.parsed_bufs[item.bufnr] = true
  end

  vim.api.nvim_win_set_cursor(self.winnr, { item.lnum, item.col })
end

---@return vim.api.keyset.win_config
function Preview:win_config()
  local border = vim.o.winborder == "none" and 0 or 2

  if self.config.height == "fill" then
    local qflist_win = util.find_qflist_win()

    if qflist_win then
      local statusline = vim.o.laststatus == 0 and 0 or 1
      local height = vim.o.lines - vim.api.nvim_win_get_height(qflist_win) - vim.o.cmdheight - border - statusline
      return {
        relative = "editor",
        width = vim.api.nvim_win_get_width(0),
        height = height,
        row = 0,
      }
    end
  end

  local height = self.config.height or 15

  return {
    relative = "win",
    win = vim.api.nvim_get_current_win(),
    width = vim.api.nvim_win_get_width(0),
    height = height,
    row = -1 * height - border,
  }
end

---@return boolean
function Preview:is_open()
  return self.winnr ~= nil
end

---@param bufnr number
---@return string
function Preview:title(bufnr)
  return fs.normalize_path(vim.fn.bufname(bufnr), vim.fn.getcwd())
end

function Preview:open()
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then
    return
  end

  local item = self:curr_item()

  ---@type vim.api.keyset.win_config
  local winconfig = vim.tbl_extend("force", { col = 1, focusable = false }, self:win_config(), self.config.win or {})

  if self.config.show_name then
    winconfig.title = self:title(item.bufnr)
    winconfig.title_pos = "left"
  end

  self.winnr = vim.api.nvim_open_win(item.bufnr, false, winconfig)

  vim.wo[self.winnr].relativenumber = false
  vim.wo[self.winnr].number = true
  vim.wo[self.winnr].winblend = 0
  vim.wo[self.winnr].cursorline = true

  self:highlight(item)
end

function Preview:close()
  if not self:is_open() then
    return
  end

  if vim.api.nvim_win_is_valid(self.winnr) then
    local force = true
    vim.api.nvim_win_close(self.winnr, force)
    self.winnr = nil
  end
end

function Preview:refresh()
  if not self:is_open() then
    self:open()
    return
  end

  local item = self:curr_item()

  vim.api.nvim_win_set_buf(self.winnr, item.bufnr)
  if self.config.show_name then
    vim.api.nvim_win_set_config(self.winnr, { title = self:title(item.bufnr) })
  end

  self:highlight(item)
end

return Preview
