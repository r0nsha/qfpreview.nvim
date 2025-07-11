-- TODO: support vertically split qflist

local defaults = require("qfpreview.config").defaults
local fs = require("qfpreview.fs")

---@class qfpreview.Preview
---@field config qfpreview.Config
---@field winnr number
---@field parsed_bufs table<number, boolean>
local Preview = {}
Preview.__index = Preview

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

---@return integer
function Preview:bufnr()
  return vim.api.nvim_win_get_buf(self.winnr)
end

function Preview:disable_lsp()
  local bufnr = self:bufnr()

  if not self.config.opts.lsp then
    for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end

  vim.diagnostic.enable(self.config.opts.diagnostics, { bufnr = bufnr })
end

---@param qfwin number
---@return number,number
local function get_aligned_col_width(qfwin)
  local has_border = vim.o.winborder ~= "none"
  local col = vim.api.nvim_win_get_position(qfwin)[2]
  local width = vim.api.nvim_win_get_width(qfwin)

  if not has_border then
    return col, width
  end

  if (col + width) == vim.o.columns then
    return col + 1, width - 1
  elseif col == 0 then
    return col, width - 1
  else
    return col - 1, width
  end
end

---@param qfwin number
---@return vim.api.keyset.win_config
function Preview:win_config(qfwin)
  local has_border = vim.o.winborder ~= "none"
  local border_width = has_border and 2 or 0
  local col, width = get_aligned_col_width(qfwin)

  if self.config.ui.height == "fill" then
    local statusline_height = vim.o.laststatus == 0 and 0 or 1
    local height = vim.o.lines - vim.api.nvim_win_get_height(qfwin) - vim.o.cmdheight - border_width - statusline_height

    if height < 0 then
      height = 15
    end

    return {
      relative = "editor",
      width = width,
      height = height,
      row = 0,
      col = col,
      focusable = false,
    }
  end

  local height = self.config.ui.height or 15

  return {
    relative = "win",
    win = vim.api.nvim_get_current_win(),
    width = width,
    height = height,
    row = -1 * height - border_width,
    col = col,
    focusable = false,
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

---@param qfwin number
function Preview:open(qfwin)
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then
    return
  end

  local item = self:curr_item()

  ---@type vim.api.keyset.win_config
  local winconfig = vim.tbl_extend("force", self:win_config(qfwin), self.config.ui.win or {})

  if self.config.ui.show_name then
    winconfig.title = self:title(item.bufnr)
    winconfig.title_pos = "left"
  end

  self.winnr = vim.api.nvim_open_win(item.bufnr, false, winconfig)
  self:disable_lsp()

  vim.wo[self.winnr].relativenumber = false
  vim.wo[self.winnr].number = true
  vim.wo[self.winnr].winblend = 0
  vim.wo[self.winnr].cursorline = true

  vim.api.nvim_win_set_cursor(self.winnr, { item.lnum, item.col })
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

---@param qfwin number
function Preview:refresh(qfwin)
  if not self:is_open() then
    self:open(qfwin)
    return
  end

  local item = self:curr_item()

  vim.api.nvim_win_set_buf(self.winnr, item.bufnr)
  if self.config.ui.show_name then
    local win_config = vim.tbl_extend("force", self:win_config(qfwin), { title = self:title(item.bufnr) })
    vim.api.nvim_win_set_config(self.winnr, win_config)
  end

  vim.api.nvim_win_set_cursor(self.winnr, { item.lnum, item.col })
end

return Preview
