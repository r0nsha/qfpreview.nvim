local M = {}

function M.find_qflist_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
      return win
    end
  end
  return nil
end

return M
