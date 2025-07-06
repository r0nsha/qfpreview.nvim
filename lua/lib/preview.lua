local util = require("lib.util")

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

---@class qfpreview.Config
---@field height number | "fill"
---@field title fun(bufnr: number): string | false

---@class qfpreview.Preview
---@field config qfpreview.Config
---@field preview_win_id number
---@field parsed_buffers table<number, boolean>
local Preview = {}
Preview.__index = Preview

---@type qfpreview.Config
local defaults = {
  height = "fill",
  title = function(bufnr)
    return vim.api.nvim_buf_get_name(bufnr)
  end,
}

---@param config? qfpreview.Config
---@return qfpreview.Preview
function Preview:new(config)
  local p = {
    config = vim.tbl_deep_extend("force", defaults, config or {}),
    preview_win_id = nil,
    parsed_buffers = {},
  }
  setmetatable(p, self)
  self.__index = self
  return p
end

---@return boolean
function Preview:is_closed()
  return self.preview_win_id == nil
end

---@param opts { preview_win_id: number, item_index: number}
function Preview:highlight(opts)
  ---@type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  local curr_item = qf_list[opts.item_index]

  if not self.parsed_buffers[curr_item.bufnr] then
    vim.api.nvim_buf_call(curr_item.bufnr, function()
      vim.cmd("filetype detect")
      pcall(vim.treesitter.start, curr_item.bufnr)
    end)
    self.parsed_buffers[curr_item.bufnr] = true
  end

  vim.api.nvim_win_set_cursor(opts.preview_win_id, { curr_item.lnum, curr_item.col })
end

---@return vim.api.keyset.win_config
function Preview:win_config()
  if self.config.height == "fill" then
    local qflist_win = util.find_qflist_win()

    if qflist_win then
      local statusline = vim.o.laststatus == 0 and 0 or 1
      local border = vim.o.winborder == "none" and 0 or 2
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
    row = -1 * height,
  }
end

function Preview:open()
  ---@type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then
    return
  end

  local curr_linenr = vim.fn.line(".")
  local curr_item = qf_list[curr_linenr]

  local winconfig = vim.tbl_extend("force", { col = 1, focusable = false }, self:win_config())
  if self.config.title then
    winconfig.title = self.config.title(curr_item.bufnr)
    winconfig.title_pos = "left"
  end
  self.preview_win_id = vim.api.nvim_open_win(curr_item.bufnr, false, winconfig)

  vim.wo[self.preview_win_id].relativenumber = false
  vim.wo[self.preview_win_id].number = true
  vim.wo[self.preview_win_id].winblend = 0
  vim.wo[self.preview_win_id].cursorline = true

  self:highlight({ preview_win_id = self.preview_win_id, item_index = curr_linenr })
end

function Preview:close()
  if self:is_closed() then
    return
  end

  if vim.api.nvim_win_is_valid(self.preview_win_id) then
    local force = true
    vim.api.nvim_win_close(self.preview_win_id, force)
    self.preview_win_id = nil
  end
end

function Preview:refresh()
  if self:is_closed() then
    self:open()
    return
  end

  ---@type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  local curr_linenr = vim.fn.line(".")
  local curr_item = qf_list[curr_linenr]

  vim.api.nvim_win_set_buf(self.preview_win_id, curr_item.bufnr)

  if self.config.title then
    vim.api.nvim_win_set_config(self.preview_win_id, { title = self.config.title(curr_item.bufnr) })
  end

  self:highlight({ preview_win_id = self.preview_win_id, item_index = curr_linenr })
end

return Preview
